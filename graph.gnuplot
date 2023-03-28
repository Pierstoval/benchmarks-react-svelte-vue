set datafile separator ';'
datafile = 'output/'.output_file.'.csv'
runtime_datafile = 'output/'.output_file.'_runtime.csv'

# Functions
    colorRatio = 1
    perc(i)=( ( ( ( (i - 1) % 7 ) + 1) * 3.0 ) / 21.0 )
    mainColor(i)=hsv2rgb(perc(i), 1, 1)
    meanColor(i)=hsv2rgb(perc(i), 0.8, 1)
    rperc(i)=( ( ( ( (i - 1) % 3 ) + 1) * 3.0 ) / 9.0 )
    runtimeColor(i)=hsv2rgb(rperc(i), 1, 1)
    meanRuntimeColor(i)=hsv2rgb(rperc(i), 0.8, 1)
    xLabel(x) = system(sprintf('head headers.csv -n 1 | cut -d ";" -f%d', x))
    x2Label(x) = system(sprintf('head headers_runtime.csv -n 1 | cut -d ";" -f%d | tr "_" " "', x))
    xPosition(n) = n

# Disables handling of the 1st row in the CSV file
set key autotitle columnhead

# Disables legend panel
unset key

# Boxes for right-part of the plot
    set boxwidth 0.8
    set style fill solid

# Generate plot statistics, like for retrieving average/mean values
    array plotstats[24]
    array runtime_plotstats[24]

    do for [i=1:24] {
     stats datafile using i name "stat" nooutput
     plotstats[i]=stat_mean
    }
    do for [i=1:24] {
     stats runtime_datafile using i name "stat" nooutput
     runtime_plotstats[i]=stat_mean
    }

# Save as PNG
    set terminal png size 1200,1400
    set output 'output/'.output_file.'.png'

set label "Benchmarking Svelte, React and Vue" font ",35pt" at screen 0.5,0.972 center front

### Start multiplot (4x1 layout)
set multiplot

# --- yarn install time
    set size 1,0.175
    set origin 0,0.78
    do for [i=1:8] {
        set arrow from i, graph 0 to i, graph 1 lc rgb("#dddddd") nohead
    }
    set xtics ('Svelte' 1,'Svelte Kit' 2,'React' 3,'React-Vite' 4,'React-Next.js' 5,'Vue' 6,'Vue-Nuxt' 7, 'Angular' 8)
    set xrange [0.5:8.5]
    set format y "% g ms"
    set ytics 5000 nomirror
    set yrange [0:30000]
    set grid ytics
    set title "Yarn install execution time (smaller is better)" font ",24pt" center
    plot for [i=1:8] datafile using (xPosition(i)):i with linespoints pointtype 1 pointsize 0.75 lc rgb mainColor(i), \
        for [i=1:8] datafile using (xPosition(i)):(plotstats[i]) with points pointtype 4 pointsize 3 lw 2 lc rgb meanColor(i)

# --- build time
    set size 1,0.175
    set origin 0,0.60
    do for [i=9:16] {
        set arrow from i, graph 0 to i, graph 1 lc rgb("#dddddd") nohead
    }
    set xtics ('Svelte' 9,'Svelte Kit' 10,'React' 11,'React-Vite' 12,'React-Next.js' 13,'Vue' 14,'Vue-Nuxt' 15, 'Angular' 16)
    set xrange [8.5:16.5]
    set format y "% g ms"
    set ytics 5000 nomirror
    set yrange [0:25000]
    set grid ytics
    set title "Yarn build execution time (smaller is better)" font ",24pt" center
    plot for [i=9:16] datafile using (xPosition(i)):i with linespoints pointtype 1 pointsize 0.75 lc rgb mainColor(i), \
        for [i=9:16] datafile using (xPosition(i)):(plotstats[i]) with points pointtype 4 pointsize 3 lw 2 lc rgb meanColor(i)

# --- build size
    set size 1,0.175
    set origin 0,0.42
    set xtics ('Svelte' 17,'Svelte Kit' 18,'React' 19,'React-Vite' 20,'React-Next.js' 21,'Vue' 22,'Vue-Nuxt' 23, 'Angular' 24)
    set xrange [16.5:24.5]
    set ytics 100 nomirror
    set yrange [0:700]
    set format y "% g KB"
    set lmargin at screen 0.087
    set title "Final build size (smaller is better)" font ",24pt" center
    plot for [i=17:24] datafile using (xPosition((i))):i with boxes lc rgb mainColor(i)

# --- Runtime performances
    set size 1,0.38
    set origin 0,0.03
    unset xtics
    set xrange [0.5:24.5]
    set format y "% g ms"
    set ytics 500 nomirror
    set yrange [11000:16000]
    set grid ytics
    do for [i=1:24] {
        set arrow from i, graph 0 to i, graph 1 lc rgb("#dddddd") nohead
    }
    do for [i=1:8] {
        set arrow from (i*3)+0.5, graph 0 to (i*3)+0.5, graph 1 lc rgb("#000000") lw 2 nohead
    }
    set title "Runtime execution tests (smaller is better)" font ",24pt" center

    # Browsers
    set label "■ Chromium" at screen 0.25,0.02 font "Arial,20pt" center tc rgb runtimeColor(1)
    set label "■ Firefox" at screen 0.5,0.02 font "Arial,20pt" center tc rgb runtimeColor(2)
    set label "■ Webkit" at screen 0.75,0.02 font "Arial,20pt" center tc rgb runtimeColor(3)

    # Sections
    set label "Svelte" at 2,16060 font "Arial,14pt" center
    set label "Svelte Kit" at 5,16060 font "Arial,14pt" center
    set label "React" at 8,16060 font "Arial,14pt" center
    set label "React-Vite" at 11,16060 font "Arial,14pt" center
    set label "React-Next" at 13.99,16060 font "Arial,14pt" center
    set label "Vue" at 17,16060 font "Arial,14pt" center
    set label "Vue-Nuxt" at 20,16060 font "Arial,14pt" center
    set label "Angular" at 23,16060 font "Arial,14pt" center

    plot for [i=1:24] runtime_datafile using (xPosition(i)):i with linespoints pointtype 1 pointsize 0.75 lc rgb runtimeColor(i), \
        for [i=1:24] runtime_datafile using (xPosition(i)):(runtime_plotstats[i]) with points pointtype 4 pointsize 3 lw 2 lc rgb meanRuntimeColor(i)

unset multiplot

### End multiplot
