% Annotate a condition as `BooleanField`
---
type: pattern
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
