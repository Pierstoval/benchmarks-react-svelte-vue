use std::collections::HashMap;
use clap::Arg;
use clap::command;
use std::fs;
use std::fs::File;
use std::os::unix::ffi::OsStrExt;
use csv::Reader;
use plotters::backend::BitMapBackend;
use plotters::chart::ChartBuilder;
use plotters::style::BLUE;
use plotters::style::WHITE;
use plotters::drawing::IntoDrawingArea;
use plotters::element::Circle;
use plotters::style::IntoFont;
use plotters::style::Color;

fn main() {
    let matches = command!() // requires `cargo` feature
        .arg(Arg::new("output_dir"))
        .arg_required_else_help(true)
        .get_matches();

    let output_dir: Option<&String> = matches.get_one("output_dir");
    let output_dir = output_dir.unwrap();

    let mut csv_content = get_csv_contents(output_dir);

    generate_graph(&mut csv_content);
}

type CsvContent = HashMap<String, Reader<File>>;

#[derive(Debug, serde::Deserialize)]
struct CsvRecord {
    install_time: u32,
    build_time: u32,
    deps_with_duplicates: u32,
    deps_without_duplicates: u32,
    build_size: u32,
}

fn get_csv_contents(output_dir: &String) -> CsvContent {
    let mut apps = fs::read_dir("../apps/")
        .unwrap()
        // Resolve paths to OsString to utf8 vector
        .map(|path| path.unwrap().file_name().as_bytes().to_vec())
        // Convert to String
        .map(|path| String::from_utf8(path).unwrap())
        .collect::<Vec<String>>()
    ;
    apps.sort();

    let csv_contents = apps.iter().map(|app| {
        let csv_path = format!("../output/{}/{}.csv", output_dir, app);
        let file = File::open(&csv_path).expect(&format!("Could not open csv file {}", csv_path));
        let csv_reader = csv::ReaderBuilder::new()
            .has_headers(true)
            .delimiter(b';')
            .from_reader(file)
        ;
        return (app.to_string(), csv_reader);
    })
        .collect::<CsvContent>()
        ;
    csv_contents
}

const OUT_FILE_NAME: &'static str = "graph.png";
const OUT_IMG_SIZE: (u32, u32) = (1200, 800);

fn generate_graph(csv_contents: &mut CsvContent) {
    dbg!("Generate graph");

    let root = BitMapBackend::new(OUT_FILE_NAME, OUT_IMG_SIZE)
        .into_drawing_area();
    root.fill(&WHITE).unwrap();

    let min_x: i32 = 0;
    let max_x: i32 = csv_contents.len() as i32;

    let min_y: i32 = 0;
    let max_y: i32 = 2500;

    let mut chart = ChartBuilder::on(&root)
        .x_label_area_size(60)
        .y_label_area_size(60)
        .margin_bottom(30)
        .margin_right(20)
        .caption("Benchmarking", ("sans-serif", 50.0).into_font())
        .build_cartesian_2d(min_x..max_x, min_y..max_y)
        .unwrap()
    ;

    chart
        .configure_mesh()
        .light_line_style(&WHITE)
        .x_desc("Application".to_string())
        .set_all_tick_mark_size(15)
        .draw()
        .unwrap()
    ;

    for (index, (_chart_name, csv_reader)) in csv_contents.iter_mut().enumerate() {
        chart.draw_series(
            csv_reader.deserialize().enumerate().map(|(index2, record)| {
                let csv_line: CsvRecord = record.unwrap();
                Circle::new((1 + index as i32, csv_line.install_time as i32), 2, BLUE.filled())
            })
        ).unwrap();
    }

    // To avoid the IO failure being ignored silently, we manually call the present function
    root
        .present()
        .expect("Unable to write result to file")
    ;

}
