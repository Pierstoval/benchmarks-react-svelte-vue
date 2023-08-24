use std::collections::HashMap;
use clap::Arg;
use clap::command;
use std::env;
use std::fs;
use std::fs::File;
use std::io::Write;
use std::os::unix::ffi::OsStrExt;
use csv::Reader;
use plotters::backend::BitMapBackend;
use plotters::chart::{ChartBuilder, ChartContext};
use plotters::coord::combinators::WithKeyPoints;
use plotters::coord::Shift;
use plotters::coord::types::{RangedCoordf32, RangedCoordi32};
use plotters::style::BLACK;
use plotters::style::HSLColor;
use plotters::style::TextStyle;
use plotters::style::WHITE;
use plotters::style::TRANSPARENT;
use plotters::drawing::DrawingArea;
use plotters::drawing::IntoDrawingArea;
use plotters::element::CandleStick;
use plotters::element::Rectangle;
use plotters::element::PathElement;
use plotters::prelude::{BindKeyPoints, Cartesian2d};
use plotters::style::IntoFont;
use plotters::style::Color;
use serde::Deserialize;

const OUT_IMG_SIZE: (u32, u32) = (600, 1800);

const X_COORDS_MULTIPLIER: i32 = 100;

type RecordsMap = Vec<(String, Vec<CsvRecord>)>;

#[derive(PartialEq)]
enum ShowMeans {
    True,
    False,
}

#[derive(Debug, Hash, Eq, Copy, Clone)]
enum ChartType {
    InstallTime,
    BuildTime,
    DepsWithDuplicates,
    DepsWithoutDuplicates,
    BuildSize,
    Chromium,
    Firefox,
    Webkit,
}
impl PartialEq for ChartType {
    fn eq(&self, other: &Self) -> bool {
        self == other
    }
}


enum PointDisplayType {
    HorizontalLine,
    Bar,
}

#[derive(Debug)]
struct Means {
    min: f32,
    q1: f32,
    median: f32,
    q3: f32,
    max: f32,
}

#[derive(Debug, Deserialize, Clone)]
struct CsvRecord {
    #[serde(skip_deserializing)]
    index: i32,
    install_time: f32,
    build_time: f32,
    deps_with_duplicates: f32,
    deps_without_duplicates: f32,
    build_size: f32,
    chromium: f32,
    firefox: f32,
    webkit: f32,
}

fn main() {
    let matches = command!() // requires `cargo` feature
        .arg(Arg::new("output_dir"))
        .get_matches();

    let mut output_dir: Option<String> = None;

    let out_dir_from_args: Option<&String> = matches.get_one("output_dir");

    if let Some(out_dir_from_args) = out_dir_from_args {
        output_dir = Some(out_dir_from_args.clone());
    } else {
        if let Ok(out_dir_from_env) = std::env::var("OUTPUT_DIR") {
            output_dir = Some(out_dir_from_env.clone());
        }
    }

    if output_dir.is_none() {
        std::io::stderr().write("Error: please specify the \"output_dir\" first argument, or use the \"OUTPUT_DIR\" environment variable.".as_ref()).unwrap();
        std::process::exit(1);
    }

    let output_dir = output_dir.unwrap();

    let cwd = std::env::current_dir().unwrap();

    let records_map = get_csv_records(output_dir.clone());
    let file_name = cwd.join("output").join(format!("graph_{}.png", output_dir)).display().to_string();
    // let title = format!("Benchmarks for {}", output_dir);

    let root = BitMapBackend::new(file_name.as_str(), OUT_IMG_SIZE)
        .into_drawing_area()
    ;
    root.fill(&WHITE).unwrap();

    let maximums = get_maximums(&records_map);

    let max_x = records_map.len() as i32;

    let roots = root.split_evenly((6, 1));

    create_chart(&roots.get(0).unwrap(), &records_map, max_x, 0.0, maximums.install_time, PointDisplayType::HorizontalLine, ChartType::InstallTime, ShowMeans::True);
    create_chart(&roots.get(1).unwrap(), &records_map, max_x, 0.0, maximums.build_time, PointDisplayType::HorizontalLine, ChartType::BuildTime, ShowMeans::True);
    create_chart(&roots.get(2).unwrap(), &records_map, max_x, 0.0, maximums.build_size, PointDisplayType::Bar, ChartType::BuildSize, ShowMeans::False);
    create_chart(&roots.get(3).unwrap(), &records_map, max_x, 0.0, maximums.deps_with_duplicates, PointDisplayType::Bar, ChartType::DepsWithDuplicates, ShowMeans::False);
    create_chart(&roots.get(4).unwrap(), &records_map, max_x, 0.0, maximums.deps_without_duplicates, PointDisplayType::Bar, ChartType::DepsWithoutDuplicates, ShowMeans::False);
    create_browser_chart(&roots.get(5).unwrap(), &records_map, max_x, maximums);

    // To avoid the IO failure being ignored silently, we manually call the present function
    root
        .present()
        .expect("Unable to write result to file")
    ;
}

fn get_means_from_records(records: &Vec<CsvRecord>, data_type: ChartType) -> Means {
    let mut filtered: Vec<i32> = records.iter().map(|record| {
        match data_type {
            ChartType::InstallTime => record.install_time as i32,
            ChartType::BuildTime => record.build_time as i32,
            ChartType::DepsWithDuplicates => record.deps_with_duplicates as i32,
            ChartType::DepsWithoutDuplicates => record.deps_without_duplicates as i32,
            ChartType::BuildSize => record.build_size as i32,
            ChartType::Chromium => record.chromium as i32,
            ChartType::Firefox => record.firefox as i32,
            ChartType::Webkit => record.webkit as i32,
        }
    })
        .filter(|value| value > &0)
        .collect();
    filtered.sort();

    let sorted = filtered;
    let len = sorted.len();

    let q1 = sorted.get(len / 4).unwrap().clone() as f32;
    let q3 = sorted.get(len * 3 / 4).unwrap().clone() as f32;
    let min = sorted.first().unwrap().clone() as f32;
    let max = sorted.last().unwrap().clone() as f32;
    let median = sorted.get(len / 2).unwrap().clone() as f32;

    Means {
        min,
        q1,
        median,
        q3,
        max,
    }
}

fn get_csv_records(output_dir: String) -> RecordsMap {
    let cwd = std::env::current_dir().unwrap();
    let mut apps = fs::read_dir(cwd.join("apps"))
        .expect("Could not locate \"apps\" directory.")
        // Resolve paths to OsString to utf8 vector
        .map(|path| path.unwrap().file_name().as_bytes().to_vec())
        // Convert to String
        .map(|path| String::from_utf8(path).unwrap())
        .collect::<Vec<String>>()
    ;
    apps.sort();

    let base_csv_path = cwd.join("output");

    let mut records = apps
        .iter()
        .map(|app| {
            let csv_path = format!("{}/{}/{}.csv", base_csv_path.display(), output_dir, app);
            let app = app.clone();
            let file = File::open(&csv_path).expect(&format!("Could not open csv file {}", csv_path));
            let csv_reader = csv::ReaderBuilder::new()
                .has_headers(true)
                .delimiter(b';')
                .from_reader(file)
            ;
            return (app.to_string(), csv_reader);
        })
        .collect::<HashMap<String, Reader<File>>>()
        .iter_mut()
        .map(|(app, csv_reader)| {
            let app = app.clone();
            let records = csv_reader.deserialize().map(|record| {
                let mut record: CsvRecord = record.unwrap();
                let app_index = apps.clone().iter().position(|r| r.eq(app.as_str())).expect(format!("Could not find app \"{}\".", app).as_str());
                record.index = app_index as i32 + 1;
                record
            }).collect::<Vec<CsvRecord>>();

            (app, records)
        })
        .collect::<RecordsMap>()
        ;

    // Sort by app name
    records.sort_by(|a, b| a.0.cmp(&b.0));

    records
}

fn get_maximums(records_map: &RecordsMap) -> CsvRecord {
    let mut maximums = CsvRecord {
        index: 0,
        install_time: 0.0,
        build_time: 0.0,
        deps_with_duplicates: 0.0,
        deps_without_duplicates: 0.0,
        build_size: 0.0,
        chromium: 0.0,
        firefox: 0.0,
        webkit: 0.0,
    };

    for (_chart_name, records) in records_map.iter() {
        for record in records {
            if record.install_time > maximums.install_time {
                maximums.install_time = record.install_time;
            }
            if record.build_time > maximums.build_time {
                maximums.build_time = record.build_time;
            }
            if record.deps_with_duplicates > maximums.deps_with_duplicates {
                maximums.deps_with_duplicates = record.deps_with_duplicates;
            }
            if record.deps_without_duplicates > maximums.deps_without_duplicates {
                maximums.deps_without_duplicates = record.deps_without_duplicates;
            }
            if record.build_size > maximums.build_size {
                maximums.build_size = record.build_size;
            }
            if record.chromium > maximums.chromium {
                maximums.chromium = record.chromium;
            }
            if record.firefox > maximums.firefox {
                maximums.firefox = record.firefox;
            }
            if record.webkit > maximums.webkit {
                maximums.webkit = record.webkit;
            }
        }
    }

    maximums
}

fn create_chart(
    root: &DrawingArea<BitMapBackend, Shift>,
    csv_records: &RecordsMap,
    max_x: i32,
    min_y: f32,
    max_y: f32,
    point_display_type: PointDisplayType,
    chart_type: ChartType,
    show_means: ShowMeans
) {
    let apps = csv_records.iter().map(|(app, _records)| { app.clone() }).collect::<Vec<String>>();
    let mut x_key_points = apps.iter().enumerate().map(|(index, _)| X_COORDS_MULTIPLIER * index as i32).collect::<Vec<i32>>();
    x_key_points.push(x_key_points.last().unwrap() + X_COORDS_MULTIPLIER);
    let min_x: i32 = 0;

    // Add 5% to max Y to allow the chart to breathe on the top
    let max_y = max_y * 1.025;

    let number_of_apps = csv_records.len() as f64;

    let chart_title = match chart_type {
        ChartType::InstallTime => "Install time (in ms)",
        ChartType::BuildTime => "Build time (in ms)",
        ChartType::DepsWithDuplicates => "Deps with duplicates",
        ChartType::DepsWithoutDuplicates => "Deps without duplicates",
        ChartType::BuildSize => "Build size (in KB)",
        _ => panic!("Browser charts are not supposed to be rendered in the \"create_chart\" function.")
    }.to_string();

    let mut chart = ChartBuilder::on(&root)
        .x_label_area_size(60)
        .y_label_area_size(60)
        .margin_top(10)
        .margin_right(15)
        .margin_bottom(15)
        .margin_left(15)
        .caption(chart_title.clone(), ("sans-serif", 20.0).into_font())
        // "+1" is here to allow the chart to breathe on the right side.
        .build_cartesian_2d((min_x..((max_x+1)*X_COORDS_MULTIPLIER)).with_key_points(x_key_points), min_y..max_y)
        .unwrap()
    ;

    let mut iter = csv_records.clone();
    iter.sort_by(|a, b| a.0.cmp(&b.0));

    for (_chart_name, records) in iter {
        let index = records.get(0).unwrap().index as f64;
        let percentage = index / number_of_apps;

        let color = HSLColor(percentage.into(), 1.0, 0.5).filled();

        let value_function = |record: &CsvRecord| {
            match chart_type {
                ChartType::InstallTime => record.install_time,
                ChartType::BuildTime => record.build_time,
                ChartType::DepsWithDuplicates => record.deps_with_duplicates,
                ChartType::DepsWithoutDuplicates => record.deps_without_duplicates,
                ChartType::BuildSize => record.build_size,
                _ => panic!("Browser charts are not supposed to be rendered in the \"create_chart\" function.")
            }
        };

        match point_display_type {
            PointDisplayType::Bar => {
                chart.draw_series(
                    records.iter()
                        .filter(|record| value_function(record) > 0.0)
                        .map(|record| {
                            let y_value = value_function(record);
                            Rectangle::new([
                               (X_COORDS_MULTIPLIER * record.index - 20, 0.0),
                               (X_COORDS_MULTIPLIER * record.index + 20, y_value),
                           ], color.clone())
                        })
                )
                    .unwrap();
            }
            PointDisplayType::HorizontalLine => {
                chart.draw_series(
                    records.iter()
                        .filter(|record| value_function(record) > 0.0)
                        .map(|record| {
                        let y_value = value_function(record);
                        PathElement::new(vec![
                            (X_COORDS_MULTIPLIER * record.index - 30, y_value), // Left
                            (X_COORDS_MULTIPLIER * record.index + 30, y_value), // Right
                        ], color.clone())
                    })
                )
                    .unwrap();
            }
        };

        if show_means == ShowMeans::True {
            draw_candlesticks(&mut chart, records.get(0).unwrap().index * X_COORDS_MULTIPLIER, get_means_from_records(&records, chart_type), 7);
        }
    }

    chart
        .configure_mesh()
        .light_line_style(&TRANSPARENT)
        .x_label_formatter(&|v: &i32| {
            let v = v.clone();
            for (name, records) in csv_records.clone().iter() {
                let index = records.get(0).unwrap().index * X_COORDS_MULTIPLIER;
                if index == v {
                    return name.clone();
                }
            }
            "".into()
        })
        .y_desc(chart_title)
        .x_label_style(("sans-serif", 12))
        .set_all_tick_mark_size(5)
        .draw()
        .unwrap()
    ;
}

fn create_browser_chart(
    root: &DrawingArea<BitMapBackend, Shift>,
    csv_records: &RecordsMap,
    max_x: i32,
    maximums: CsvRecord,
) {
    // This is necessary because if we only use integer as indices for the X axis,
    // then plotters will not allow us to put stuff at non-integer coords.
    // And as float coords do not seem possible, we'll use parts of coords by multiplying by this number:
    let apps = csv_records.iter().map(|(app, _records)| { app.clone() }).collect::<Vec<String>>();
    let mut x_key_points = apps.iter().enumerate().map(|(index, _)| X_COORDS_MULTIPLIER * index as i32).collect::<Vec<i32>>();
    x_key_points.push(x_key_points.last().unwrap() + X_COORDS_MULTIPLIER);
    let min_x: i32 = 0;

    let mut min_y = f32::MAX;
    for (_, records) in csv_records.iter() {
        for record in records.iter() {
            if min_y > record.firefox && record.firefox > 0.0 {
                min_y = record.firefox;
            }
            if min_y > record.chromium && record.chromium > 0.0 {
                min_y = record.chromium;
            }
            if min_y > record.webkit && record.webkit > 0.0 {
                min_y = record.webkit;
            }
        }
    }
    let min_y = min_y * 0.975;

    let mut max_y = maximums.chromium;
    if maximums.firefox > max_y {
        max_y = maximums.firefox;
    }
    if maximums.webkit > max_y {
        max_y = maximums.webkit;
    }

    let max_y = max_y * 1.05;

    let chart_title = "In-browser execution (in ms)";

    let x_label_position = (OUT_IMG_SIZE.0 / 5) as i32;
    let y_label_position = (OUT_IMG_SIZE.1 / 7) as i32;

    root.draw_text("― Chromium", &TextStyle::from(("sans-serif", 20).into_font()).color(&HSLColor(0.0, 1.0, 0.5)), (x_label_position.clone(), y_label_position.clone())).unwrap();
    root.draw_text("― Webkit", &TextStyle::from(("sans-serif", 20).into_font()).color(&HSLColor(0.333, 1.0, 0.5)), (x_label_position.clone() * 2, y_label_position.clone())).unwrap();
    root.draw_text("― Firefox", &TextStyle::from(("sans-serif", 20).into_font()).color(&HSLColor(0.666, 1.0, 0.75)), (x_label_position.clone() * 3, y_label_position.clone())).unwrap();

    let mut chart = ChartBuilder::on(&root)
        .x_label_area_size(60)
        .y_label_area_size(60)
        .margin_top(10)
        .margin_right(15)
        .margin_bottom(15)
        .margin_left(15)
        .caption(chart_title.clone(), ("sans-serif", 20.0).into_font())
        // "+1" is here to allow the chart to breathe on the right side.
        .build_cartesian_2d((min_x..((max_x+1)*X_COORDS_MULTIPLIER)).with_key_points(x_key_points), min_y..max_y)
        .unwrap()
    ;

    let mut iter = csv_records.clone();
    iter.sort_by(|a, b| a.0.cmp(&b.0));

    for (_chart_name, records) in iter {
        draw_browser_chart(&mut chart, &records, ChartType::Chromium, HSLColor(0.0, 1.0, 0.5), -23);
        draw_browser_chart(&mut chart, &records, ChartType::Webkit, HSLColor(0.333, 1.0, 0.5), 0);
        draw_browser_chart(&mut chart, &records, ChartType::Firefox, HSLColor(0.666, 1.0, 0.75), 23);
    }

    chart
        .configure_mesh()
        .light_line_style(&TRANSPARENT)
        .x_label_formatter(&|v: &i32| {
            let v = v.clone();
            for (name, records) in csv_records.clone().iter() {
                let index = records.get(0).unwrap().index * X_COORDS_MULTIPLIER;
                if index == v {
                    return name.clone();
                }
            }
            "".into()
        })
        .y_desc(chart_title)
        .x_label_style(("sans-serif", 12))
        .set_all_tick_mark_size(5)
        .draw()
        .unwrap()
    ;
}

fn draw_browser_chart(
    chart: &mut ChartContext<BitMapBackend, Cartesian2d<WithKeyPoints<RangedCoordi32>, RangedCoordf32>>,
    records: &Vec<CsvRecord>,
    data_type: ChartType,
    color: HSLColor,
    horizontal_offset: i32,
) {
    let mut x_coordinate = 0;

    chart.draw_series(
        records.iter()
            .filter(|record| {
                match data_type {
                    ChartType::Chromium => record.chromium > 1.0,
                    ChartType::Firefox => record.firefox > 1.0,
                    ChartType::Webkit => record.webkit > 1.0,
                    _ => panic!("Non-browser charts cannot be displayed as browser charts"),
                }
            })
            .map(|record| {
                let y_value =
                    match data_type {
                        ChartType::Chromium => record.chromium,
                        ChartType::Firefox => record.firefox,
                        ChartType::Webkit => record.webkit,
                        _ => panic!("Non-browser charts cannot be displayed as browser charts"),
                    }
                ;
                if x_coordinate == 0 { x_coordinate = record.index * X_COORDS_MULTIPLIER + horizontal_offset; }
                PathElement::new(vec![
                    (x_coordinate.clone() - 5, y_value),
                    (x_coordinate.clone() + 5, y_value),
                ], color.filled().stroke_width(0))
            })
    )
        .unwrap();

    draw_candlesticks(chart, x_coordinate, get_means_from_records(&records, data_type), 5);
}

fn draw_candlesticks(chart: &mut ChartContext<BitMapBackend, Cartesian2d<WithKeyPoints<RangedCoordi32>, RangedCoordf32>>, x_coordinate: i32, means: Means, candle_width: i32) {
    let whiskers_width = (candle_width as f32 * 1.5).ceil() as i32;
    chart.draw_series(vec![CandleStick::new(x_coordinate, means.q3, means.max, means.min, means.q1, &BLACK, &BLACK, (candle_width * 2) as u32)]).unwrap();
    chart.draw_series(vec![
        PathElement::new(vec![(x_coordinate - whiskers_width, means.min), (x_coordinate + whiskers_width, means.min)], &BLACK),
        PathElement::new(vec![(x_coordinate - whiskers_width, means.median), (x_coordinate + whiskers_width, means.median)], &BLACK),
        PathElement::new(vec![(x_coordinate - whiskers_width, means.max), (x_coordinate + whiskers_width, means.max)], &BLACK)
    ]).unwrap();
}
