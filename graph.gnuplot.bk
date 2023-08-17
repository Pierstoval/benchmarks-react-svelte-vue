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
    thresholdRatio = 8

    maxInstallTime = system(sprintf('cat "%s" | tail -n +2 | awk -F ";" "{print \$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8}" | tr " " "\n"| grep -v "^$" | sort -n | tail -1', datafile))
    minInstallTime = system(sprintf('cat "%s" | tail -n +2 | awk -F ";" "{print \$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8}" | tr " " "\n"| grep -v "^$" | sort -n | head -1', datafile))
    installThreshold = floor(maxInstallTime / (100 * thresholdRatio)) * 100

    maxBuildTime = system(sprintf('cat "%s" | tail -n +2 | awk -F ";" "{print \$9,\$10,\$11,\$12,\$13,\$14,\$15,\$16}" | tr " " "\n"| grep -v "^$" | sort -n | tail -1', datafile))
    buildTimeThreshold = floor(maxBuildTime / (100 * thresholdRatio)) * 100

    maxBuildSize = system(sprintf('cat "%s" | tail -n +2 | awk -F ";" "{print \$17,\$18,\$19,\$20,\$21,\$22,\$23,\$24}" | tr " " "\n"| grep -v "^$" | sort -n | tail -1', datafile))
    buildSizeThreshold = floor(maxBuildSize / (100 * 5)) * 100

    maxRuntime = system(sprintf('cat "%s" | tail -n +2 | awk -F ";" "{print \$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8,\$9,\$10,\$11,\$12,\$13,\$14,\$15,\$16,\$17,\$18,\$19,\$20,\$21,\$22,\$23,\$24}" | tr " " "\n"| grep -v "^$" | sort -n | tail -1', runtime_datafile))
    minRunTime = system(sprintf('cat "%s" | tail -n +2 | awk -F ";" "{print \$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8,\$9,\$10,\$11,\$12,\$13,\$14,\$15,\$16,\$17,\$18,\$19,\$20,\$21,\$22,\$23,\$24}" | tr " " "\n"| grep -v "^$" | sort -n | head -1', runtime_datafile))
    runtimeThreshold = floor((maxRuntime - minRunTime) / (100 * thresholdRatio)) * 100

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
    set ytics installThreshold nomirror
    set yrange [0:maxInstallTime+500]
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
    set ytics buildTimeThreshold nomirror
    set yrange [0:maxBuildTime+100]
    set grid ytics
    set title "Yarn build execution time (smaller is better)" font ",24pt" center
    plot for [i=9:16] datafile using (xPosition(i)):i with linespoints pointtype 1 pointsize 0.75 lc rgb mainColor(i), \
        for [i=9:16] datafile using (xPosition(i)):(plotstats[i]) with points pointtype 4 pointsize 3 lw 2 lc rgb meanColor(i)

# --- build size
    set size 1,0.175
    set origin 0,0.42
    set xtics ('Svelte' 17,'Svelte Kit' 18,'React' 19,'React-Vite' 20,'React-Next.js' 21,'Vue' 22,'Vue-Nuxt' 23, 'Angular' 24)
    set xrange [16.5:24.5]
    set ytics buildSizeThreshold nomirror
    set yrange [0:maxBuildSize+20]
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
    set ytics runtimeThreshold nomirror
    set yrange [minRunTime-20:maxRuntime+20]
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
    set label "Svelte" at screen 0.1425,0.375 font "Arial,14pt" center
    set label "Svelte Kit" at screen 0.255,0.375 font "Arial,14pt" center
    set label "React" at screen 0.365,0.375 font "Arial,14pt" center
    set label "React-Vite" at screen 0.475,0.375 font "Arial,14pt" center
    set label "React-Next" at screen 0.59,0.375 font "Arial,14pt" center
    set label "Vue" at screen 0.695,0.375 font "Arial,14pt" center
    set label "Vue-Nuxt" at screen 0.81,0.375 font "Arial,14pt" center
    set label "Angular" at screen 0.92,0.375 font "Arial,14pt" center

    plot for [i=1:24] runtime_datafile using (xPosition(i)):i with linespoints pointtype 1 pointsize 0.75 lc rgb runtimeColor(i), \
        for [i=1:24] runtime_datafile using (xPosition(i)):(runtime_plotstats[i]) with points pointtype 4 pointsize 3 lw 2 lc rgb meanRuntimeColor(i)

unset multiplot

### End multiplot
