# LrExamples

This repository includes a set of examples for use in the parsing articles on [benoithiller.com/parsing](https://benoithiller.com/parsing).

The code is thus formatted specifically to render well in the articles(such as having a very narrow width), while still being in a format that can be tested.

## Structure

Currently the project is primarily composed of the following modules

* [LrExamples::Lr0](lib/lr_examples/lr0.rb) containing most of the generic tools for LR parser construction.
* [LrExamples::Lalr](lib/lr_examples/lalr.rb) building on `Lr0` with additional code needed to generate a LALR parser.

## Testing

If you want to run the tests yourself you can install the dependencies by doing:

```bash
bundle install
```

Then make use of the following command to run the rspec tests:

```
rake spec
```
