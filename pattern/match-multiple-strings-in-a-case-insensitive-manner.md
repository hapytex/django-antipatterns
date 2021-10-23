% Match multiple strings in a case-insensitive manner
---
type: pattern
typefa: "fas fa-shapes"
tags: [regex, string-matching]
layers: [orm, models, views]
related_packages: []
solinks: []
---

It often happens that we have a list of strings, and we want to obtain
model objects where a certain field contains at least one of the given strings.
Often this is also checked in a case-*in*sensitive way, such that `'apple'` and
`'APPLE'` are considered equivalent.

Usually we have a list of items that we want to match with that field, for example:

```python
fruits = ['apple', 'blueberry', 'coconut', 'dragonfruit']
```

an for example look for `Post` objects where the `content` field contains
at least one of these elements in a case-*in*sensitive way.

# What problems are solved with this?

We can not make use of the [**`__in`** lookup [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/querysets/#in)
since this will only match items that contain exactly the name of one fruit in case-sensitive way.
This thus means that the content should be `'apple'`, not <s>`'APPLE'`</s>, <s>`'Apple'`</s>, <s>`'An apple'`</s>, etc.:

```python
Post.objects.filter(
    content__in=fruits
)
```

will thus only retrieve posts with one word: the name of a fruit defined in the `fruits` list.

With the pattern described here, we can perform a case-insensitive match where we can decide if the
item should start with the name of a fruit, end with the name of a fruit, or simply contain the
name of a fruit.

# What does this pattern look like?

Regular expressions can be used to look for multiple items with one expression. The only thing that
we have to do is convert our `fruits` list to a regular expression that will simultaneously look
for an `'apple'`, `'blueberry'`, etc. Such regular expression looks like `'(apple|blueberry|coconut|dragonfruit)'`.
If we want to restrict this further such that the content *begins* with an element of the `fruits` list,
we can use a caret (`^`): `'^(apple|blueberry|coconut|dragonfruit)'` will only match contents that start
with one of the elements. We can also make use of the end anchor `$` such that the content *ends* with the given
item.

There are however some problems we will need to overcome. It is for example possible that the name of the `fruits`
contain a dot (`.`), pipe character (`|`), etc. If we join items simply together, then it is possible that we
thus will match different items. One can use the [**<code>escape(&hellip;)</code>** function [Python-doc]](https://docs.python.org/3/library/re.html#re.escape)
to escape the items in the `fruits` list such that tokens that have a special meaning in a regex are escaped.

If we want to match case-insensitive, this means we should use the
[**`__iregex`** lookup [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/querysets/#iregex).
If we thus have a list `fruits` with the name of the fruits, we can construct a regex and filter with:

<pre class="python"><code>from re import escape

myregex = f'^({&quot;|&quot;.join(<b>escape(</b>fruit<b>)</b> for fruit in fruits)})$'

Post.objects.filter(
    <b>content__iregex=myregex</b>
)</code></pre>

The `^` and/or `$` can be removed if it is not required that the item is found at start/end of the `content` respectively.
