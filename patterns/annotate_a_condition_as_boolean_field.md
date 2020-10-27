% Annotate a condition as boolean field

One sometimes does not want to filter on a condition, but use a condition as a
boolean field.

# What is solved with this?

One can use `Q` objects to filter a condition. But sometimes you also want to
use it in an annotation. For example to add an extra attribute to the model
objects, or to order for example.

# How does the pattern look like?

One can wrap the `Q` object in a `ExpressionWrapper` and specify the
`BooleanField` as <code>output_field=&hellip;</code>, for example:

```python3
MyModel.objects.annotate(
    my_condition=ExpressionWrapper(
        Q(pk__lt=14),
        output_field=BooleanField()
    )
)
```
