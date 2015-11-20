# Dart Poisson Disc

Generators of Poisson Disc point distributions.

## Current Features

* 2D Poisson Disc point distributions generated using [Bridson's Algorithm](https://www.cs.ubc.ca/~rbridson/docs/bridson-siggraph07-poissondisk.pdf)

See these two pages for easy to digest explainations of the algorithm:

* [http://bost.ocks.org/mike/algorithms/](http://bost.ocks.org/mike/algorithms/)
* [https://www.jasondavies.com/poisson-disc/](https://www.jasondavies.com/poisson-disc/)

## Getting started

1. Add the following to your project's pubspec.yaml and run `pub get`:

    ```yaml
    dependencies:
      poisson_disc: '^2.0.0'
    ```
2. Add the correct import for your project:

    ```dart
    import 'package:poisson_disc/bridson2.dart' as bridson2;
    ```
3. Invoke:

    ```dart
	for (Vector2 v in bridson2.generate(wdth: 256, hght: 128, toroidal: true)) {
	  // Do something with points here
	}
	```

## Examples

1. `./example/bridson2`

    Demonstrates toroidal and non-toroidal Poisson Disc distributions an compares probability distributions of points for each.
    
    