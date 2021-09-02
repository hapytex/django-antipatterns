% Using multiple forms on the same page without prefixing
---
severity: 3
type: antipattern
typefa: "fas fa-ban"
tags: [prefix, modelform]
layers: [views, forms]
related_packages: []
solinks: []
---

Some views do not work with one form, but with *multiple* forms. In that
case it is important to work with prefixes such that the two forms will
each process their part of the composite form.

# Why is it a problem?

For example one can make two forms to fill in data about the father and
the mother with:

```python3
from django import forms

class FatherForm(forms.Form):
    name = forms.CharField()
    first_name = forms.CharField()

class MotherForm(forms.Form):
    name = forms.CharField()
    first_name = forms.CharField()
```

The view then might be defined as:

<pre class="python3"><code>from django.shortcuts import redirect, render

def some_view(request):
    if request.method == 'POST':
        father_form = <b>FatherForm(</b>request.POST<b>)</b>
        mother_form = <b>MotherForm(</b>request.POST<b>)</b>
        if father_form.is_valid() and mother_form.is_valid():
            # process the data &hellip;
            return redirect('<i>name-of-some-view</i>')
    else:
        father_form = FatherForm()
        mother_form = MotherForm()
    return render(
        request,
        '<i>name-of-some-template.html</i>',
        {'father_form': father_form, 'mother_form': mother_form}
    )</code></pre>

The problem is that if we process data with this view, the request
will post two values for `name` and two values for `first_name`. The
logic of the [**`QueryDict`** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/request-response/#django.http.QueryDict)
means that if we want to get the value for `name` and/or `first_name`;
it will use the *last* value that was defined. This thus means that
if we render the forms with:

<pre class="django"><code>&lt;form method=&quot;POST&quot; action=&quot;{% url 'name-of-some-view' %}&quot;&gt;
    {% csrf_token %}
    {{ <b>father_form</b> }}
    {{ <b>mother_form</b> }}
&lt;/form&gt;</code></pre>

both the `father_form` and the `mother_form` will use data from the form elements of the form of the mother.
This is because the request will simply send two values for the `name` and the `first_name` item, and the
two forms, will both use the last value defined.

# What can be done to resolve the problem?

Django has a solution for this: it can *prefix* the name of the form elements with a
[**<code>prefix=&hellip;</code>** parameter [Django-doc]](https://docs.djangoproject.com/en/dev/ref/forms/api/#django.forms.Form.prefix).
This prefix parameter will add a prefix to all the form input items that arise from that
form. For example if we specify `prefix='father'` for the `FatherForm`, then the name
of the items will be `father-name`, and `father-first_name`. This thus means that Django
now can process these as part of the `FatherForm`, and the others as part of the `MotherForm`.

Strictly speaking, for *n* forms, we can decide to only give *n-1* a prefix and this will work,
but it is likely more elegant that all the *n* forms have a *unique* prefix. It is important
that the prefixes are unique, since otherwise the same problem will arise.

We need to specify the prefix for both the GET and the POST codepath, so that means that the
view will look like:

<pre class="python"><code>from django.shortcuts import redirect, render

def some_view(request):
    if request.method == 'POST':
        father_form = FatherForm(request.POST<b>, prefix='father'</b>)
        mother_form = MotherForm(request.POST<b>, prefix='mother'</b>)
        if father_form.is_valid() and mother_form.is_valid():
            # process the data &hellip;
            return redirect('<i>name-of-some-view</i>')
    else:
        father_form = FatherForm(<b>prefix='father'</b>)
        mother_form = MotherForm(<b>prefix='mother'</b>)
    return render(
        request,
        '<i>name-of-some-template.html</i>',
        {'father_form': father_form, 'mother_form': mother_form}
    )</code></pre>

# Extra tips

Django has a [**`FormSet`** class [Django-doc]](https://docs.djangoproject.com/en/dev/topics/forms/formsets/)
to render a (large) collection of forms each with a different prefix, this makes it more
easy to route data to the correct form without having to worry about the prefixes oneself.
