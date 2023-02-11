posX(n) = n

set datafile separator ';'
datafile = 'results.csv'
firstrow = system('head -1 '.datafile)

set key autotitle columnhead
unset key

set bmargin 8
set xtics 1 scale 1 rotate by -33 offset -0.1
set xrange [0.5:19.5]
set xlabel "Commands"
set ylabel "Execution time"
set y2label "Build size"
set title "Benchmarking Svelte, React and Vue"

set format y "% g ms"
set format y2 "% g KB"

set grid ytics
set ytics 3000 nomirror
set y2tics 100
set yrange [0:29000]
set y2range [0:966.66666]

# Plots separator
set arrow from 2.5, graph 0 to 2.5, graph 1 lc rgb("#cccccc") nohead
set arrow from 4.5, graph 0 to 4.5, graph 1 lc rgb("#cccccc") nohead
set arrow from 6.5, graph 0 to 6.5, graph 1 lc rgb("#cccccc") nohead
set arrow from 8.5, graph 0 to 8.5, graph 1 lc rgb("#cccccc") nohead
set arrow from 10.5, graph 0 to 10.5, graph 1 lc rgb("#cccccc") nohead
set arrow from 12.56, graph 0 to 12.56, graph 1 lc rgb("#cccccc") nohead
set arrow from 13.5*1.1, graph 0 to 13.5*1.1, graph 1 lc rgb("#cccccc") nohead
set arrow from 15.5*1.1, graph 0 to 15.5*1.1, graph 1 lc rgb("#cccccc") nohead

set boxwidth 0.8
set style fill solid

array plotstats[18]

do for [i=1:18] {
 stats datafile using i name "stat" nooutput
 plotstats[i]=stat_mean
}

colorRatio = 0.5
perc(i)=((i*colorRatio)+(18.0-18.0*colorRatio))/18

mainColor(i)=hsv2rgb(perc(i), 1, 1)
meanColor(i)=hsv2rgb(perc(i), 0.75, 1)

means(x) = plotstats[x]

xLabel(x) = system(sprintf('cat '.datafile.' | head -1 | cut -d ";" -f%d', x))

plot for [i=1:12] datafile using (posX(i)):i:xticlabel(xLabel(i)) with linespoints pointtype 1 pointsize 0.75 lc rgb mainColor(i), \
    for [i=1:12] datafile using (posX(i)):(means(i)) with points pointtype 4 pointsize 3 lw 2 lc rgb meanColor(i), \
    for [i=13:18] datafile using (posX((i-1)*1.1)):i:xticlabel(xLabel(i)) with boxes axis x1y2 lc rgb mainColor(i)

set terminal png size 1100,700
set output 'output.png'

replot

exit
