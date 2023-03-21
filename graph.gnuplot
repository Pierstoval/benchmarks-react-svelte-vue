set datafile separator ';'
datafile = 'results.csv'
runtime_datafile = 'results_runtime.csv'

# Functions
    colorRatio = 1
    perc(i)=( ( ( ( (i - 1) % 7 ) + 1) * 3.0 ) / 21.0 )
    mainColor(i)=hsv2rgb(perc(i), 1, 1)
    meanColor(i)=hsv2rgb(perc(i), 0.8, 1)
    rperc(i)=( ( ( ( (i - 1) % 3 ) + 1) * 3.0 ) / 9.0 )
    runtimeColor(i)=hsv2rgb(rperc(i), 1, 1)
    meanRuntimeColor(i)=hsv2rgb(rperc(i), 0.8, 1)
    xLabel(x) = system(sprintf('head results.csv -n 1 | cut -d ";" -f%d', x))
    x2Label(x) = system(sprintf('head results_runtime.csv -n 1 | cut -d ";" -f%d | tr "_" " "', x))
    xPosition(n) = n

# Disables handling of the 1st row in the CSV file
set key autotitle columnhead

# Disables legend panel
unset key

# Boxes for right-part of the plot
    set boxwidth 0.8
    set style fill solid

# Generate plot statistics, like for retrieving average/mean values
    array plotstats[21]
    array runtime_plotstats[21]

    do for [i=1:21] {
     stats datafile using i name "stat" nooutput
     plotstats[i]=stat_mean
    }
    do for [i=1:21] {
     stats runtime_datafile using i name "stat" nooutput
     runtime_plotstats[i]=stat_mean
    }

# Save as PNG
    set terminal png size 1200,1400
    set output 'output.png'

set label "Benchmarking Svelte, React and Vue" font ",35pt" at screen 0.5,0.972 center front

### Start multiplot (4x1 layout)
set multiplot

# --- yarn install time
    set size 1,0.175
    set origin 0,0.78
    do for [i=1:7] {
        set arrow from i, graph 0 to i, graph 1 lc rgb("#dddddd") nohead
    }
    set xtics ('Svelte' 1,'Svelte Kit' 2,'React' 3,'React-Vite' 4,'React-Next.js' 5,'Vue' 6,'Vue-Nuxt' 7)
    set xrange [0.5:7.5]
    set format y "% g ms"
    set ytics 5000 nomirror
    set yrange [0:30000]
    set grid ytics
    set title "Yarn install execution time" font ",24pt" center
    plot for [i=1:7] datafile using (xPosition(i)):i with linespoints pointtype 1 pointsize 0.75 lc rgb mainColor(i), \
        for [i=1:7] datafile using (xPosition(i)):(plotstats[i]) with points pointtype 4 pointsize 3 lw 2 lc rgb meanColor(i)

# --- build time
    set size 1,0.175
    set origin 0,0.60
    do for [i=8:14] {
        set arrow from i, graph 0 to i, graph 1 lc rgb("#dddddd") nohead
    }
    set xtics ('Svelte' 8,'Svelte Kit' 9,'React' 10,'React-Vite' 11,'React-Next.js' 12,'Vue' 13,'Vue-Nuxt' 14)
    set xrange [7.5:14.5]
    set format y "% g ms"
    set ytics 5000 nomirror
    set yrange [0:25000]
    set grid ytics
    set title "Yarn build execution time" font ",24pt" center
    plot for [i=8:14] datafile using (xPosition(i)):i with linespoints pointtype 1 pointsize 0.75 lc rgb mainColor(i), \
        for [i=8:14] datafile using (xPosition(i)):(plotstats[i]) with points pointtype 4 pointsize 3 lw 2 lc rgb meanColor(i)

# --- build size
    set size 1,0.175
    set origin 0,0.42
    set xtics ('Svelte' 15,'Svelte Kit' 16,'React' 17,'React-Vite' 18,'React-Next.js' 19,'Vue' 20,'Vue-Nuxt' 21)
    set xrange [14.5:21.5]
    set ytics 100 nomirror
    set yrange [0:700]
    set format y "% g KB"
    set lmargin at screen 0.087
    set title "Final build size" font ",24pt" center
    plot for [i=15:21] datafile using (xPosition((i))):i with boxes lc rgb mainColor(i)

# --- Runtime performances
    set size 1,0.38
    set origin 0,0.03
    unset xtics
    set xrange [0.5:21.5]
    set format y "% g ms"
    set ytics 500 nomirror
    set yrange [13500:16000]
    set grid ytics
    do for [i=1:21] {
        set arrow from i, graph 0 to i, graph 1 lc rgb("#dddddd") nohead
    }
    do for [i=1:7] {
        set arrow from (i*3)+0.5, graph 0 to (i*3)+0.5, graph 1 lc rgb("#000") lw 2 nohead
    }
    set title "Runtime execution tests" font ",24pt" center

    # Browsers
    set label "■ Chromium" at 5,13300 font "Arial,20pt" center tc rgb runtimeColor(1)
    set label "■ Firefox" at 10,13300 font "Arial,20pt" center tc rgb runtimeColor(2)
    set label "■ Webkit" at 15,13300 font "Arial,20pt" center tc rgb runtimeColor(3)

    # Sections
    set label "Svelte" at 2,16060 font "Arial,14pt" center
    set label "Svelte Kit" at 5,16060 font "Arial,14pt" center
    set label "React" at 8,16060 font "Arial,14pt" center
    set label "React-Vite" at 11,16060 font "Arial,14pt" center
    set label "React-Next" at 13.99,16060 font "Arial,14pt" center
    set label "Vue" at 17,16060 font "Arial,14pt" center
    set label "Vue-Nuxt" at 20,16060 font "Arial,14pt" center
    plot for [i=1:21] runtime_datafile using (xPosition(i)):i with linespoints pointtype 1 pointsize 0.75 lc rgb runtimeColor(i), \
        for [i=1:21] runtime_datafile using (xPosition(i)):(runtime_plotstats[i]) with points pointtype 4 pointsize 3 lw 2 lc rgb meanRuntimeColor(i)

unset multiplot

### End multiplot
