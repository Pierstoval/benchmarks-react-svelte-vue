use std::collections::HashMap;
use clap::Arg;
use clap::command;
use std::fs;
use std::fs::File;
use std::os::unix::ffi::OsStrExt;
use csv::Reader;
use plotters::backend::BitMapBackend;
use plotters::chart::ChartBuilder;
use plotters::coord::Shift;
use plotters::style::HSLColor;
use plotters::style::WHITE;
use plotters::style::TRANSPARENT;
use plotters::drawing::DrawingArea;
use plotters::drawing::IntoDrawingArea;
use plotters::element::Circle;
use plotters::element::PathElement;
use plotters::prelude::BindKeyPoints;
use plotters::style::IntoFont;
use plotters::style::Color;
use serde::Deserialize;

const OUT_FILE_NAME: &'static str = "graph.png";
const OUT_IMG_SIZE: (u32, u32) = (1000, 1500);

type RecordsMap = Vec<(String, Vec<CsvRecord>)>;

enum ChartType {
    InstallTime,
    BuildTime,
    DepsWithDuplicates,
    DepsWithoutDuplicates,
    BuildSize,
}

enum PointDisplayType {
    Circle,
    HorizontalLine,
}

#[derive(Debug, Deserialize, Clone)]
struct CsvRecord {
    #[serde(skip_deserializing)]
    index: i32,
    install_time: i32,
    build_time: i32,
    deps_with_duplicates: i32,
    deps_without_duplicates: i32,
    build_size: i32,
    chromium: i32,
    firefox: i32,
    webkit: i32,
}

fn main() {
    let matches = command!() // requires `cargo` feature
        .arg(Arg::new("output_dir"))
        .arg_required_else_help(true)
        .get_matches();

    let output_dir: Option<&String> = matches.get_one("output_dir");
    let output_dir = output_dir.unwrap();

    let records_map = get_csv_records(output_dir);

    let root = BitMapBackend::new(OUT_FILE_NAME, OUT_IMG_SIZE)
        .into_drawing_area();
    root.fill(&WHITE).unwrap();

    let maximums = get_maximums(&records_map);

    let max_x = records_map.len() as i32;

    let roots = root.split_evenly((5, 1));

    create_chart(&roots.get(0).unwrap(), &records_map, max_x, 0, maximums.install_time, PointDisplayType::HorizontalLine, ChartType::InstallTime);
    create_chart(&roots.get(1).unwrap(), &records_map, max_x, 0, maximums.build_time, PointDisplayType::HorizontalLine, ChartType::BuildTime);
    create_chart(&roots.get(2).unwrap(), &records_map, max_x, 0, maximums.build_size, PointDisplayType::Circle, ChartType::BuildSize);
    create_chart(&roots.get(3).unwrap(), &records_map, max_x, 0, maximums.deps_with_duplicates, PointDisplayType::Circle, ChartType::DepsWithDuplicates);
    create_chart(&roots.get(4).unwrap(), &records_map, max_x, 0, maximums.deps_without_duplicates, PointDisplayType::Circle, ChartType::DepsWithoutDuplicates);

    // To avoid the IO failure being ignored silently, we manually call the present function
    root
        .present()
        .expect("Unable to write result to file")
    ;
}

fn get_csv_records(output_dir: &String) -> RecordsMap {
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
        install_time: 0,
        build_time: 0,
        deps_with_duplicates: 0,
        deps_without_duplicates: 0,
        build_size: 0,
        chromium: 0,
        firefox: 0,
        webkit: 0,
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
    min_y: i32,
    max_y: i32,
    point_display_type: PointDisplayType,
    chart_type: ChartType,
) {
    // This is necessary because if we only use integer as indices for the X axis,
    // then plotters will not allow us to put stuff at non-integer coords.
    // And as float coords do not seem possible, we'll use parts of coords by multiplying by this number:
    let x_coords_multiplier = 10;

    let apps = csv_records.iter().map(|(app, _records)| { app.clone() }).collect::<Vec<String>>();
    let mut x_key_points = apps.iter().enumerate().map(|(index, _)| x_coords_multiplier * index as i32).collect::<Vec<i32>>();
    x_key_points.push(x_key_points.last().unwrap() + x_coords_multiplier);
    let min_x: i32 = 0;

    // Add 5% to max Y to allow the chart to breathe on the top
    let max_y = (max_y as f32 * 1.05) as i32;

    let number_of_apps = csv_records.len() as f64;

    let chart_title = match chart_type {
        ChartType::InstallTime => "Install time (in ms)",
        ChartType::BuildTime => "Build time (in ms)",
        ChartType::DepsWithDuplicates => "Deps with duplicates",
        ChartType::DepsWithoutDuplicates => "Deps without duplicates",
        ChartType::BuildSize => "Build size (in KB)",
    }.to_string();

    let mut chart = ChartBuilder::on(&root)
        .x_label_area_size(60)
        .y_label_area_size(60)
        .margin_top(10)
        .margin_right(15)
        .margin_bottom(15)
        .margin_left(15)
        .caption(chart_title.clone(), ("sans-serif", 50.0).into_font())
        // "+1" is here to allow the chart to breathe on the right side.
        .build_cartesian_2d((min_x..((max_x+1)*x_coords_multiplier)).with_key_points(x_key_points), min_y..max_y)
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
            }
        };

        match point_display_type {
            PointDisplayType::Circle => {
                chart.draw_series(
                    records.iter().map(|record| {
                        let y_value = value_function(record);
                        Circle::new((x_coords_multiplier * record.index, y_value), 5, color.clone())
                    })
                )
                    .unwrap();
            }
            PointDisplayType::HorizontalLine => {
                chart.draw_series(
                    records.iter().map(|record| {
                        let y_value = value_function(record);
                        PathElement::new(vec![
                            (x_coords_multiplier * record.index - 3, y_value), // Left
                            (x_coords_multiplier * record.index + 3, y_value), // Right
                        ], color.clone())
                    })
                )
                    .unwrap();
            }
        };
    }

    chart
        .configure_mesh()
        .light_line_style(&TRANSPARENT)
        .x_label_formatter(&|v: &i32| {
            let v = v.clone();
            for (name, records) in csv_records.clone().iter() {
                let index = records.get(0).unwrap().index * x_coords_multiplier;
                if index == v {
                    return name.clone();
                }
            }
            "".into()
        })
        .x_desc("Framework".to_string())
        .x_label_style(("sans-serif", 20))
        .y_desc(chart_title)
        .x_label_style(("sans-serif", 20))
        .set_all_tick_mark_size(5)
        .draw()
        .unwrap()
    ;
}
