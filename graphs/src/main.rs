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
use plotters::style::{BLACK, BLUE, RGBColor};
use plotters::style::WHITE;
use plotters::drawing::DrawingArea;
use plotters::drawing::IntoDrawingArea;
use plotters::element::Circle;
use plotters::style::IntoFont;
use plotters::style::Color;
use serde::Deserialize;

const OUT_FILE_NAME: &'static str = "graph.png";
const OUT_IMG_SIZE: (u32, u32) = (1200, 800);

type RecordsMap = Vec<(String, (u32, Vec<CsvRecord>))>;

enum ChartType {
    InstallTime,
    BuildTime,
    DepsWithDuplicates,
    DepsWithoutDuplicates,
    BuildSize,
}

#[derive(Debug, Deserialize)]
struct CsvRecord {
    #[serde(skip_deserializing)]
    index: i32,
    install_time: i32,
    build_time: i32,
    deps_with_duplicates: i32,
    deps_without_duplicates: i32,
    build_size: i32,
}

fn main() {
    let matches = command!() // requires `cargo` feature
        .arg(Arg::new("output_dir"))
        .arg_required_else_help(true)
        .get_matches();

    let output_dir: Option<&String> = matches.get_one("output_dir");
    let output_dir = output_dir.unwrap();

    // 2 readers are necessary because they can't be rewinded, and we need 2 loops:
    // One to calculate maximum values (to allow chart to be correctly positioned).
    // The other one to actually plot data into the chart.
    let mut records_map = get_csv_records(output_dir);

    let root = BitMapBackend::new(OUT_FILE_NAME, OUT_IMG_SIZE)
        .into_drawing_area();
    root.fill(&WHITE).unwrap();

    let maximums = get_maximums(&records_map);

    let max_x = records_map.len() as i32;

    create_chart(&root, &mut records_map, max_x, maximums.install_time, ChartType::InstallTime);
    // create_chart(&root, &mut records_map, max_x, maximums.build_size, ChartType::BuildSize);

    // To avoid the IO failure being ignored silently, we manually call the present function
    root
        .present()
        .expect("Unable to write result to file")
    ;
}

fn get_csv_records(output_dir: &String) -> RecordsMap {
    let mut apps = fs::read_dir("../apps/")
        .unwrap()
        // Resolve paths to OsString to utf8 vector
        .map(|path| path.unwrap().file_name().as_bytes().to_vec())
        // Convert to String
        .map(|path| String::from_utf8(path).unwrap())
        .collect::<Vec<String>>()
    ;
    apps.sort();

    let mut records = apps
        .iter()
        .map(|app| {
            let csv_path = format!("../output/{}/{}.csv", output_dir, app);
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
        .enumerate()
        .map(|(index, (chart_name, csv_reader))| {
            let chart_name = chart_name.clone();
            let records = csv_reader.deserialize().map(|record| {
                let record: CsvRecord = record.unwrap();
                record
            }).collect::<Vec<CsvRecord>>();

            (chart_name, (index as u32, records))
        })
        .collect::<RecordsMap>()
        ;

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
    };

    for (_chart_name, (_, records)) in records_map.iter() {
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
        }
    }

    maximums
}

fn create_chart(
    root: &DrawingArea<BitMapBackend, Shift>,
    csv_records: &mut RecordsMap,
    max_x: i32,
    max_y: i32,
    chart_type: ChartType,
) {
    let min_x: i32 = 0;
    let min_y: i32 = 0;

    let max_y = (max_y as f32 * 1.1) as i32;

    let chart_title = match chart_type {
        ChartType::InstallTime => "Install time",
        ChartType::BuildTime => "Build time",
        ChartType::DepsWithDuplicates => "Deps with duplicates",
        ChartType::DepsWithoutDuplicates => "Deps without duplicates",
        ChartType::BuildSize => "Build size",
    }.to_string();

    let mut chart = ChartBuilder::on(&root)
        .x_label_area_size(60)
        .y_label_area_size(60)
        .margin_bottom(30)
        .margin_right(20)
        .caption(chart_title, ("sans-serif", 50.0).into_font())
        .build_cartesian_2d(min_x..max_x, min_y..max_y)
        .unwrap()
    ;

    let iter = csv_records;
    iter.sort_by(|a, b| a.0.cmp(&b.0));

    for (chart_name, (index, records)) in iter {
        let chart_name = chart_name.clone();

        let color = match chart_name.as_str() {
            "angular" => RGBColor(0, 0, 255),
            "react" => RGBColor(0, 255, 255),
            "react-vite" => RGBColor(0, 255, 128),
            "react-next" => RGBColor(0, 255, 0),
            "svelte" => RGBColor(255, 255, 0),
            "svelte-kit" => RGBColor(255, 128, 0),
            "vue" => RGBColor(255, 128, 128),
            "vue-nuxt" => RGBColor(255, 0, 0),
            _ => RGBColor(128, 128, 128),
        }.filled();

        chart.draw_series(
            records.iter().map(|record| {
                let y_value = match chart_type {
                    ChartType::InstallTime => record.install_time,
                    ChartType::BuildTime => record.build_time,
                    ChartType::DepsWithDuplicates => record.deps_with_duplicates,
                    ChartType::DepsWithoutDuplicates => record.deps_without_duplicates,
                    ChartType::BuildSize => record.build_size,
                };
                Circle::new((1 + *index as i32, y_value), 5, color)
            })
        )
            .unwrap();
    }

    chart
        .configure_mesh()
        .light_line_style(&WHITE)
        .x_desc("Application".to_string())
        .set_all_tick_mark_size(15)
        .draw()
        .unwrap()
    ;

}
