% Constructing a new form when validation fails

Often in a view a *new* form is constructed when validating a bounded form
fails, for example:

<pre><code>from django.shortcuts import redirect, render

def my_view(request):
    if request.method == 'POST':
        form = MyForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            return redirect(<i>name-of-some-view</i>)
        else:
            form = <b>MyForm()</b>
    else:
        form = MyForm()
    return render(request, '<i>name-of-some-template.html', {'form': form})</code></pre>

# Why it is a problem?

A `Form` (and `ModelForm`) is not only useful to render HTML forms, validate
input and save data to the database. It also generates *error messages*. If you
render an invalid form correctly, then it will show the error messages near the
fields, and the non-field specific error messages at the top of the form (or at
another place if you manually render this).

# What can be done to resolve the problem?

Omit constructing a new form. In case `form.is_valid()` returns `False`, just
render *that* form, and not a new one, so the view can be modified to:

<pre><code>from django.shortcuts import redirect, render

def my_view(request):
    if request.method == 'POST':
        form = MyForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            return redirect(<i>name-of-some-view</i>)
        # <i>no</i> new form
    else:
        form = MyForm()
    return render(request, '<i>name-of-some-template.html', {'form': form})</code></pre>


# Extra tips

The Django documentation has a section named
[*rendering fields manually*](https://docs.djangoproject.com/en/dev/topics/forms/#rendering-fields-manually)
that explains how to render a form that includes rendering error messages.
