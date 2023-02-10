A raw benchmark of how much time it takes to install & build React & Svelte apps, and their build size.

Example of result on my machine:

```
❯ ./test.bash
 Cleaning up... Done!
 Making sure processtime is installed... Done!
 Installing node dependencies...
 > Svelte Yarn Done!
 > Svelte Kit Yarn Done!
 > React Yarn Done!
  > React Next Yarn Done!
  > Vue Yarn Done!
  > Vue Nuxt Yarn Done!
 Building projects as static websites...
  > Svelte Build Done!
  > Svelte Kit Build Done!
  > React Build Done!
  > React Next Build Done!
  > Vue Build Done!
  > Vue Nuxt Build Done!
 Gathering complete build size...
  > Svelte Build Size Done!
  > Svelte Kit Build Size Done!
  > React Build Size Done!
  > React Next Build Size Done!
  > Vue Build Size Done!
  > Vue Nuxt Build Size Done!
 Results for node dependencies:
 ➡ svelte yarn install:       1363 ms
 ➡ svelte_kit yarn install:   5292 ms
 ➡ react yarn install:        16246 ms
 ➡ react_next yarn install:   8744 ms
 ➡ vue yarn install:          3672 ms
 ➡ vue nuxt yarn install:     23030 ms
 Results for build time:
 ➡ svelte build time:       1400 ms
 ➡ svelte-kit build time:   2210 ms
 ➡ react build time:        7387 ms
 ➡ react-next build time:   10186 ms
 ➡ vue build time:          3184 ms
 ➡ vue nuxt build time:     11889 ms
 Results for build size:
 ➡ svelte build size:       32 KB
 ➡ svelte_kit build size:   100 KB
 ➡ react build size:        604 KB
 ➡ react_next build size:   440 KB
 ➡ vue build size:          124 KB
 ➡ vue nuxt build size:     320 KB
```

Pictured results:

![](./output.png)
