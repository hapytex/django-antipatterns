% `Date(Time)Field`s that store a week or month
---
type: pattern
typefa: "fas fa-shapes"
tags: [datetime, date, week, query]
layers: [orm, model, model-fields]
related_packages: []
solinks:
- https://stackoverflow.com/q/68974578/67579
---

Sometimes we might want to specify a week in a certain month, such that
when we filter with a specific date, we look if that date is in the same
week as the one stored in the model.

We can solve this for example with an `IntegerField` and then determine
the number of weeks since a specific date, for example January 1<sup>st</sup>, 1990[^1].

The problem with such an `IntegerField` is that it takes a way a lot of
convenience to determine the week number. For example when filtering
for a specific week it requires that the programmer will need to convert
the datetime object to a week number. It will require a lot of logic
for example to join two items, or compare one week with a `date` object.

# What problems are solved with this?



# What does this pattern look like?



# Extra tips

[^1] since the first week of 1990 starts on a monday.
