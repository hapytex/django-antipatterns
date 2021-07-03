% Using a `FloatField` for money
---
severity: 2
type: antipattern
typefa: "fas fa-ban"
tags: [float-field, money, currency]
layers: [models]
related_packages: [django-money, django-moneyfield]
---

Often for quantities that require *precise* calculations, a [**`FloatField`** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#floatfield)
is used. This is not a good idea since *decimal* numbers often can not be precisely
converted to a `float`, so it will result in rounding errors. These errors will
further propagate when one performs calculations.

# Why is it a problem?

A `float` uses the [*IEEE-754 standard* [wiki]](https://en.wikipedia.org/wiki/IEEE_754)
to represent floating point numbers. While this is a good standard and actually
aims to make calculations very precise, it can result in rounding errors for
*decimal* numbers. Quantities like *currencies* make use of the decimal number
system, and often do not allow much rounding errors.

# What can be done to resolve the problem?

One can make use of a [**`DecimalField`** [Django-doc]](https://docs.djangoproject.com/en/dev/ref/models/fields/#decimalfield).
`DecimalField`s are represented at the Django/Python layer as a `Decimal`, and
at the database often use a dedicated decimal type. These represent numbers as
decimal numbers, and thus make, for decimal numbers, correct sums, etc.

<pre class="python"><code>from django.db import models

class Product(models.Model):
    price = models.<b>DecimalField(max_digits=12, decimal_places=2)</b></code></pre>

The Django documentation has a section on [*`FloatField` vs. `DecimalField`*](https://docs.djangoproject.com/en/dev/ref/models/fields/#floatfield-vs-decimalfield)
which compares both types.

# Extra tips

There are Django packages that make it more convenient to work with money. For
example [**`django-money`** [GitHub]](https://github.com/django-money/django-money/)
and [**`django-moneyfield`** [GitHub]](https://github.com/carlospalol/django-moneyfield).

These represent money with two fields, a `DecimalField` for the value, and an
extra column that denotes the currency. This is often more convenient and
provides extra functionalities like converting money from one currency to
another.
