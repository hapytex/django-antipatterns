% (Over)use of `.values()`
---
severity: 2
---

Often in views, one can find code that looks like:

<pre class="python"><code>from django.shortcuts import render

def some_view(request):
    my_objects = MyModel.objects<b>.values()</b>
    return render(request, 'some_template.html', {'my_objects': my_objects})</code></pre>

The [**<code>.values(&hellip;)</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/querysets/#values)
part will return a (`QuerySet`) of *dictionaries*, not `MyModel` objects.

# Why is it a problem?

Dictionaries are less "rich". These simply map keys to values. A model enhances
that with several extra functionalities:

 1. validation of fields;
 2. mapping the field to its representation with
    <code>get_<i>fieldname</i>_display</code>
 3. properties added on the model;
 4. retrieve related model objects (`ForeignKey`s act like lazy queries); and
 5. updating, removing, etc. of the model to the database.

These are typical problems that arise by the [*primitive obsession* antipattern [refactoring.guru]](https://refactoring.guru/smells/primitive-obsession).

# How can we fix this?

Do *not* make use of <code>.values(&hellip;)</code> unless in *certain* circumstances. One can
make use of <code>.values(&hellip;)</code> for example to group by a certain
value. But normally using `.values()` is not a good idea, one thus better
creates a query that looks like: 

<pre class="python"><code>from django.shortcuts import render

def some_view(request):
    my_objects = MyModel.objects.all()
    return render(request, 'some_template.html', {'my_objects': my_objects})</code></pre>

# Extra tips

Sometimes people make use of **<code>.values(&hellip;)</code>** to boost queries, by only selecting columns they are interested in.
One can make use of [**<code>.only(&hellip;)</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/querysets/#only)
and [**<code>.defer(&hellip;)</code>** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/querysets/#defer) to retrieve
only a subset of the columns of the model. The remaining columns are then *lazy*
loaded with extra queries when necessary.
