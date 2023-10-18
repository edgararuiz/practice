## Overall

Good work! 

It would be helpful to do this in small, modular chunks via PRs so that it can be reviewed/discussed more easily. 

Also, write your oxygen as you go. It helps to get a jump on the documentation and might make you think about how people will interact with the software more. 

Any function with methods should have `...` as an argument. I think you maybe planned to add them? The current code would not have worked as-is when put into S3. 

## Probability binning

I’d use a name other than [`bin`](https://github.com/edgararuiz/probably/blob/ea4a85d9fd7999d477ef4652fd88a5414b1e8da2/R/calibrate.R#L499). Maybe `.bin` to avoid name conflicts [done d53124feeda9da6c149a2004406ec2e3d2132482]

Make [this code](https://github.com/edgararuiz/probably/blob/calibration/R/calibrate.R#L503:L509), along with the code to get the confidence intervals, functions. [done 1c88b35806f8f0fb7dda2cfbfb857e13254987c2]

I’m on the fence about how much the code is geared towards remote tables. It’s good future planning. However, is the Spark integration going to be complete enough for this to be used (esp in the near term)? It also adds constraints to the initial version that are not currently needed.

Generally, use the prefix `num_` instead of [`no_`](https://github.com/edgararuiz/probably/blob/calibration/R/calibrate.R#L485). [done 1c88b35806f8f0fb7dda2cfbfb857e13254987c2] 

We can still compute the [mean of the probability estimates](https://github.com/edgararuiz/probably/blob/calibration/R/calibrate.R#L505) within a bin but we should reference everything (plots, etc) by the bin midpoint. They are probably not the same thing. [done d53124feeda9da6c149a2004406ec2e3d2132482]

Let’s rename `event_ratio` to `event_rate` and `bin_total` to just `total`. [done d53124feeda9da6c149a2004406ec2e3d2132482]

We should make an argument for the confidence level and default tit to 0.90. [done 1c88b35806f8f0fb7dda2cfbfb857e13254987c2]

In our other code (like discretize steps), we specify the number of breaks (`num_breaks`) instead of `bins`. We should be consistent with that. [done 1c88b35806f8f0fb7dda2cfbfb857e13254987c2]

Not a criticism (just curious): is there a technical reason to avoid using the pipe in chained calculations (like [this one](https://github.com/edgararuiz/probably/blob/calibration/R/calibrate.R#L499:L513))? 

## Calibration functions

Let’s rename `cal_glm` to  `cal_logistic` and `cal_gam` to `cal_logistic_spline`.  [done 1c88b35806f8f0fb7dda2cfbfb857e13254987c2]

The `...` should also be passed to each of the modeling methods for calibration. [done]

The `gam()` call also needs a `family` argument. The formula should also be `.is_val ~ s(.estimate)`. [almost]

The calibration functions should save their estimates whenever possible. People are going to know what happens under the hood. 

We should also implement the same models used by the betareg package. It seems like a light package but has not be updated in a few years. It is just a set of logistic regressions. 

Is there a reason to [sort the data](https://github.com/edgararuiz/probably/blob/calibration/R/calibrate.R#L289)? If so, should we do it to the bootstrap sample too? 

The [check for a binary problem](https://github.com/edgararuiz/probably/blob/calibration/R/calibrate.R#L540:L542) should just check to see if the truth value has 3+ levels. 

One general suggestion about function calls: always namespace functions used in dependencies (even if they are explicitly imported). When using PSOCK clusters for parallel processing, leaving out the package namespace will cause issues. 

The rounding used [for joins](https://github.com/edgararuiz/probably/blob/calibration/R/calibrate.R#L117:L131) feels really brittle to me. I know that the use of `approx()` might not translate to remote tables but it is a much better solution to the problem. 

What is the `desc` [argument](https://github.com/edgararuiz/probably/blob/calibration/R/calibrate.R#L78) for? [NA]

TODO - figure if we want cal_... could accepts two named probability columns