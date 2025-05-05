1. Teléfono real
2. Catálogo de productos
3. Aplicación facebook


Administradores
1. WABA
2. de ventas


----
En el administrador WABA
Se consideran diferentes id que representan diferentes asociaciones entre entidades. Cada uno de ellos se considera waba_id en la documentación y se usa como entry_id en los mensajes envíados a webhook. 

ENTIDADES
waba         : tiene solo un fono
             : es hijo de app
             : puede no tener fono 
             : puede no tener plantillas
             : debe tener app
             : se usa conectado por un webhook

catalogo     : no está asociado a fono
             : se asocia libremente a waba, pero solo se puede usar en uno por vez

app          :es padre de waba     (administrador waba)
             :es padre de catalogo (administrador de ventas)

webhook      :es hijo de la app (plan de app)


Estando en el administrador WABA y seleccionando un waba
1. Se puede seleccionar un telefóno real para ser usado para enviar mensajes 
2. Se puede acceder a un menú para agregar plantillas de mensajes
3. Se tendrá acceso a los costos asociados
4. Se podrá asociar una cuenta para pagar los costos

Estando en el plano de la app se puede asociar un webhook a un sitio web para que pueda haber intercambio de requests entre sus respectivos endpoints.

  En esta situación es que mi applicación comienza a interactuar.
  Pero no está limitado a enviar mensajes de un waba_id o phone_id de la app que especificó y habilitó el webhoo. He probado los waba_id y phone_id para enviar plantillas de la aplicación ae, cuando el webhook fue originalmente especificado para otra aplicacioń: alec.
  La cantidad de teléfonos está limitada a solo dos. No importa la cantidad de app o de waba que se tenga. Parece que hay una cuenta superior, la comercial que establece ese límite. Uno esperaría que al crear otra app, se pudiese tener más teléfonos, pero no lo he podido hacer.
  Sin embargo, al crear un app, se pueden tener hasta dos waba con sus correspondientes plantillas y catalogo. Sin embargo no hay derecho a tener fono para esos waba. Depende del total ya asignado.


?Se puede usar un waba sin que tenga teléfono asociado?
?Se pueden crear plantillas en un waba que no tenga teléfono?
?Cómo envío esa plantilla si no tengo teléfono?



Cuando se usa la api graph para generar mensajes, esto es desde mi programa, alhacer un request WABA::Transaccion, se necesita el waba_id y/o phone_id.

Al parecer hay un uso indistinto en ciertos comandos, en la documentación, donde se solicita waba_id, no funciona con waba_id, sino con phone_id.


Uso del entry_id en los requests.

El entry_id recibido en algunos requests parece estar asociado a los id de los waba. Pero no he podido constatar la relación directa entre ambos.

Algunos mensajes, por ejemplo cuando un cliente indica un email, con un mensaje text body, no llevan entry_id.

Podríamos asumir de momento que entry_id es generado para indicar una relación con un waba en particular, el que, a su vez estaría asociado o no a un fono. Pero por lo que sé, si quisiésemos enviar una plantilla de ese waba, necesitaríamos un phone id. Esto nos lleva a considerar el entry_id como elemento secundario, es más sólido identificar el phone_id en los requests. 


Así he procedido para averiguar si un usuario está frente a un canal de colaborador o de uno de cliente. Es más o menos así. Si el cliente escribiese un text body dirigido al canal de cliente (número x) entonces solo dispongo del phone_id y no del entry_id. Así que lo tomo y decreto que estoy en el canal de cliente (x) y respondo con contenido de ese canal. Cada vez que envíe plantillas estarán marcaas con el entry_id de ese canal y phone_id. Mirando más de cerca, se enívan mensajes desde el fono del canal de cliente y el fono del cliente.


La parte que no logro visualizar es cuál webhook recibirá al cliente, si tengo dos webhook activos, en dos de mis programas (app web).
Al parecer, pude verificar que al cambiar el endpoint del webhook, los requests que se hacen llegar ahí, son los que pertenecen a la app que rige al phone_id que están contenidos en estos mensajes.


La parte más curiosa que he observado en ese tema, es que al configurar un seguido webhook en otra ap pude usar en modo de prueba, los fonos asociados a otra app. La cual tiene su propio webhook.

Esto tal vez significa que puedo usar libremene los fonos para enviar, pero si un cliente envía un mensaje a un phone, ese phone estará asociado aun webhook en particular, con lo que es equivalnete considerarlo un canal de una de mis applicaciones. De donde resulta que podría desconectar un fono desde un waba asociado a una de mis app para que esté en otra app. De desa forma podría tener un sitio web para el canal de clientes y otro para el canal de colaboradores. 


Tal vez esto me permita ir migrando a python free en cloudflare. 
