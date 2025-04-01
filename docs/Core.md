## Core

Core is what makes helium churn, without devolving in to boring technicals it includes helium's auto ui texture atlassing tech, element creation, scenes, and input subscriptions.

Relevant user facing modules:

### Element

Element is the class for every ui element, in practice it's glue between the code you write and the other parts of helium.

[Find more here](./core/Element.md)

### Input

Input allows to create callbacks for helium internal input events

[Find more here](./State-Input-Guide.md)

[and here](./core/Input-events.md)


### Scene

Scenes are just that, a composition of elements you can render, update, switch between etc.

[Find more here](./core/Scenes.md)