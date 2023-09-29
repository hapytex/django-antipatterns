% Imports
---
severity: 2
type: antipattern
typefa: "fas fa-ban"
tags: [views]
layers: [views]
related_packages:
 - name: isort
   github: PyCQA/isort
solinks: []
---

Often it's necessary to import modules used in your code and often you see them imported as below:

```python
from projects.models import Project
from django.views.generic import *

class ProjectListView(ListView):
   model = Project
   template_name = 'projects.html'
```

# Why is it a problem?

Two issues are evident above. Firstly the model `Project` is absolutely imported by hardcoding the app name. If this is done in multiple places, and then for some reason the app name `projects` changed in the future, all these imports would fail.
Secondly, you are importing everything from `django.views.generic` using `*` which accesses everything in there including what you do not need. This also means that, you are loading, into memory, modules you may not be using at all. And what if something changes in the future?

# What can be done to resolve the problem?

[PEP20](https://peps.python.org/pep-0020/) says `explicit is better than implicit` so for local imports, be as explicit as possible and use absolute imports when necessary.

The code above can be re-written thus:

```python
from django.views.generic import ListView
from .models import Project

class ProjectListView(ListView):
   model = Project
   template_name = 'projects.html'
```

# Extra tips

[**`Pep8`** ](https://pep8.org/#imports) maintains that imports be placed at the top of the 
file you are working on and should be grouped together in the order below:
- Standard libary imports
- Third party library imports
- Local/App level imports
You don't need to do this manually if you don't want to. [isort](https://github.com/PyCQA/isort) is a handy library that
can sort the imports in your file.

