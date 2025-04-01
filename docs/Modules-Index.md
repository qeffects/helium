## Modules

Helium is subdivided in to a few 'modules'

### Core

Core includes everything helium *needs* to run, this is the only critical module

Current core files relative to root:

./init.lua    
and everything in the ./core folder

With core you can create elements, scenes, subscribe to inputs inside of elements etc.

[Find more here](./Core.md)

### Hooks

Hooks are files/functions for interacting with element lifecycle, requires **core**

Hooks are the files inside 

./hooks/

They allow you to create state proxy tables, set size, position, various callbacks on load, update etc.

[Find more here](./Hooks.md)

### Shell

Shell includes higher level abstractions of state hooks and input subscriptions, requires **core** and **hooks**

Shell files are inside

./shell/

They abstract common element setups like buttons, checkboxes, text inputs, sliders etc.

### Layout

Layout includes common layout schemes, requires **core**

Layouts are inside ./layout/

[Find more here](./Layout.md)