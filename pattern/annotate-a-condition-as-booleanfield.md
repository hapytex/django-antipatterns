% Annotate a condition as `BooleanField`
---
type: pattern
typefa: "fas fa-shapes"
tags: [annotate, database-query, boolean-field]
layers: [orm]
solinks: []
---
One sometimes does not want to filter on a condition, but use a condition as a
Boolean field.

# What problems are solved with this?

One can use `Q` objects to filter a condition. But sometimes you also want to
use it in an annotation. For example to add an extra attribute to the model
objects, or to order for example.

# What does this pattern look like?

One can wrap the `Q` object in a `ExpressionWrapper` and specify the
`BooleanField` as <code>output_field=&hellip;</code>, for example:

<pre class="python"><code>from django.db.models import BooleanField, ExpressionWrapper, Q

MyModel.objects.annotate(
    my_condition=<b>ExpressionWrapper(</b>
        <b>Q(</b>pk__lt=14<b>)</b>,
        output_field=BooleanField()
    <b>)</b>
)</code></pre>

# Extra tips

One can encapsulate the logic with an expression that looks like:

<pre class="python"><code>from django.db.models import BooleanField, ExpressionWrapper, Q

def <b>Condition</b>(*args, **kwargs):
    return ExpressionWrapper(Q(*args, **kwargs), output_field=BooleanField())</code></pre>

then one can annotate the condition with:

<pre class="python"><code>MyModel.objects.annotate(
    my_condition=<b>Condition(</b>pk__lt=14<b>)</b>
)</code></pre>

the positional and named parameters can be used like one does in a [**<code>.filter(&hellip;)</code>** <sup>[Django-doc]</sup>](https://docs.djangoproject.com/en/dev/ref/models/querysets/#filter)
method call.
