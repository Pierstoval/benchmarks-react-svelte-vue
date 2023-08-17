use std::collections::HashMap;
use clap::Arg;
use clap::command;
use std::fs;
use std::fs::File;
use std::os::unix::ffi::OsStrExt;
use csv::Reader;

fn main() {
    let matches = command!() // requires `cargo` feature
        .arg(Arg::new("output_dir"))
        .arg_required_else_help(true)
        .get_matches();

    let output_dir: Option<&String> = matches.get_one("output_dir");
    let output_dir = output_dir.unwrap();

    println!("{:?}", output_dir);

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
        let mut csv_reader = csv::Reader::from_reader(file);
        return (app.to_string(), csv_reader);
    })
        .collect::<HashMap<String, Reader<File>>>()
    ;

    dbg!(csv_contents);
}
