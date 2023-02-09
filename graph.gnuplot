posX(n) = n

unset key

set xtics 1
set xrange [0:20]

set ytics 3000 nomirror
set y2tics 100
set yrange [0:27000]
set y2range [0:900]

set datafile separator ';'
plot for [i=1:12] 'results.csv' using (posX(i)):i with linespoints pointtype 1 pointsize 3
replot for [i=13:18] 'results.csv' using (posX(i+1)):i with linespoints pointtype 7 pointsize 3 axis x1y2

set terminal png
set output 'output.png'

replot
