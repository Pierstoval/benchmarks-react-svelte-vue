posX(n) = n

set datafile separator ';'
datafile = 'results.csv'
firstrow = system('head -1 '.datafile)

set key autotitle columnhead
unset key

set bmargin 8
set xtics 1 scale 0 rotate by -45
set xrange [0:20]
set xlabel "Commands"
set ylabel "Execution time"
set y2label "Build size"
set title "Benchmarking Svelte, React and Vue"

func(x) = system(sprintf('cat '.datafile.' | head -1 | cut -d ";" -f%d', x))

#set format x func(x)
set format y "% g ms"
set format y2 "% g KB"

set grid ytics
set ytics 3000 nomirror
set y2tics 100
set yrange [0:29000]
set y2range [0:966.66666]

# Plots separator
set arrow from 13, graph 0 to 13, graph 1 nohead

set boxwidth 0.8
set style fill solid

do for [i=1:18] {
 stats datafile using i name sprintf("stat_%d", i) nooutput
}

means(x) = eval "stat_".x."_mean"

plot for [i=1:12] datafile using (posX(i)):i:xticlabel(func(i)) with linespoints pointtype 1 pointsize 2, \
    for [i=1:12] datafile using (posX(i)):(means(i)) with points pointtype 1 pointsize 5, \
    for [i=13:18] datafile using (posX(i+1)):i:xticlabel(func(i)) with boxes axis x1y2

set terminal png size 1100,700
set output 'output.png'

replot
