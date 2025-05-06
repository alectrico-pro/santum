
https://developers.facebook.com/docs/whatsapp/cloud-api/webhooks/components/
https://developers.facebook.com/docs/graph-api/reference/v14.0/app/subscriptions

Este perímetro te permite leer, crear, actualizar y eliminar suscripciones a webhooks.

No se admiten las suscripciones de webhooks para Instagram y se deben configurar en el panel de apps.
Leer

Explorador de la API Graph

GET /v14.0/{app-id}/subscriptions HTTP/1.1
Host: graph.facebook.com

Permisos

    Para devolver suscripciones para esa app, se requiere un token de acceso a la app.

Campos
Nombre 	Descripción 	Tipo

object


Indica el tipo de objeto al que se aplica esta suscripción.


enum{user, page, permissions, payments}

callback_url


La URL que recibirá la solicitud de POST cuando se active una actualización.


string

fields


El conjunto de campos de este object que están suscriptos.


string[]

active


Indica si la suscripción está activa.


bool
Publicar

Puedes crear nuevas suscripciones a webhooks con el siguiente perímetro:

POST /v14.0/{app-id}/subscriptions HTTP/1.1
Host: graph.facebook.com

object=page&callback_url=http%3A%2F%2Fexample.com%2Fcallback%2F&fields=about%2C+picture&include_values=true&verify_token=thisisaverifystring

Para reactivar la suscripción, puedes hacer una solicitud de POST con los campos callback_url, verify_token y object.
Permisos

    Para agregar nuevas suscripciones para esa app, se necesita un token de acceso a la app.
    Las suscripciones para el tipo de objeto user solo serán válidas para los usuarios que tengan instalada la app.
    Las suscripciones para el tipo de objeto page solo serán válidas para las páginas que tengan instalada la app. Si quieres instalar la app para una página, usa el perímetro /{page-id}/subscribed_apps.
    Es necesario configurar la app que se usa para la suscripción de modo que reciba actualizaciones de webhooks.

Campos
Nombre 	Descripción 	Tipo

object


Indica el tipo de objeto al que se aplica esta suscripción.


enum{user, page, permissions, payments}

callback_url


La URL que recibirá la solicitud de POST cuando se active una actualización, y la solicitud de GET cuando se intente publicar esta operación. Consulta nuestra guía para crear una página de URL de devolución de llamada.


string

fields


Uno o más conjuntos de campos válidos de este object para suscripción.


string[]

include_values


Indica si las notificaciones de cambio deben incluir los valores nuevos.


bool

verify_token


Una cadena arbitraria que se puede usar para confirmar al servidor que la solicitud es válida.


string
Respuesta

Si tu URL de devolución de llamada es válida y la suscripción es correcta, se mostrará lo siguiente:

{
  "success": true
}

De lo contrario, se devolverá un mensaje de error.
Eliminar

Puedes eliminar todas las suscripciones o las suscripciones a determinados objetos con la siguiente operación:

DELETE /v14.0/{app-id}/subscriptions HTTP/1.1
Host: graph.facebook.com

object=page

Para eliminar campos específicos de tu suscripción, incluye un parámetro fields.
Permisos

    Para eliminar suscripciones de esa app, se necesita un token de acceso a la app.

Campos
Nombre 	Descripción 	Tipo

object


Tipo de objeto específico para el que se eliminarán las suscripciones. Si no se incluye este campo opcional, se eliminarán todas las suscripciones de esta app.


enum{user, page, permissions, payments}

fields


Uno o más conjuntos de campos válidos de este object para suscripción.


string[]
Respuesta

Si la operación se completa con éxito, se mostrará lo siguiente:

{
  "success": true
}

De lo contrario, se devolverá un mensaje de error.
Actualizar

Para hacer actualizaciones en este perímetro, haz una operación de publicación con nuevos valores. Esto modificará la suscripción para el tema determinado sin sobrescribir los campos existentes.

Empezar

En este documento, se explica cómo configurar un webhook que te notificará cuando los usuarios de tu app publiquen un cambio en sus fotos de usuario. Cuando entiendas cómo configurar este webhook, sabrás como configurar los demás.

Para configurar cualquier webhook, debes hacer lo siguiente:

    Crear un punto de conexión en un servidor seguro que pueda procesar solicitudes HTTPS.
    Configurar el producto Webhooks en el panel de apps de tu app.

Estos pasos se explican de manera detallada a continuación.
Creación de un punto de conexión

Tu punto de conexión debe tener la capacidad de procesar dos tipos de solicitudes HTTPS: solicitudes de verificación y notificaciones de eventos. Como ambas solicitudes utilizan HTTPS, tu servidor debe tener un certificado TLS o SSL válido, correctamente configurado e instalado. No se admiten los certificados autofirmados.

En las secciones que figuran a continuación, se explica qué incluye cada tipo de solicitud y cómo responder a cada una de ellas. De manera alternativa, puedes usar nuestra app de ejemplo, que ya está configurada para procesar esas solicitudes.
Solicitudes de verificación

Siempre que configures el producto Webhooks en el panel de apps, enviaremos una solicitud GET a la URL del punto de conexión. Las solicitudes de verificación incluyen los siguientes parámetros de cadenas de consulta, como anexos al final de la URL del punto de conexión. Se verán similares a lo siguiente:
Ejemplo de solicitud de verificación

GET https://www.your-clever-domain-name.com/webhooks? hub.mode=subscribe& hub.challenge=1158201444& hub.verify_token=meatyhamhock

Parámetro	Valor de ejemplo	Descripción

hub.mode
	

subscribe
	

Este valor siempre estará configurado como subscribe.

hub.challenge
	

1158201444
	

Un int que debes volver a transmitirnos.

hub.verify_token
	

meatyhamhock
	

Una cadena que tomamos del campo Token de verificación en el panel de apps de tu app. Configurarás esta cadena cuando completes los pasos de los parámetros de configuración de Webhooks.

Nota: PHP convierte los puntos (.) en guiones bajos (_) en los nombres de parámetros.
Validación de solicitudes de verificación

Cada vez que el punto de conexión recibe una solicitud de verificación, debe hacer lo siguiente:

    Verificar que el valor de hub.verify_token coincida con la cadena configurada en el campo Token de verificación al configurar el producto Webhooks en el panel de tu app (aún no configuraste esta cadena de token).
    Responder con el valor hub.challenge.

Si estás en tu panel de apps y configuras el producto Webhooks (y, por lo tanto, activas una solicitud de verificación), el panel indicará si el punto de conexión validó correctamente la solicitud. Si utilizas el punto de conexión /app/subscriptions de la API Graph para configurar el producto Webhooks, la API indicará si la operación fue exitosa o no con una respuesta.
Notificaciones de eventos

Cuando configures tu producto Webhooks, te suscribirás a campos (fields) específicos en un tipo de objeto (object) (por ejemplo, el campo photos en el objeto user). Siempre que haya un cambio en uno de esos campos, enviaremos a tu punto de conexión una solicitud POST con una carga JSON que describe el cambio.

Por ejemplo, si te suscribiste al campo photos del objeto user, y uno de los usuarios de tu app publicó una foto, te enviaremos una solicitud POST similar a la siguiente:

POST / HTTPS/1.1 Host: your-clever-domain-name.com/webhooks Content-Type: application/json X-Hub-Signature-256: sha256={super-long-SHA256-signature} Content-Length: 311 { "entry": [ { "time": 1520383571, "changes": [ { "field": "photos", "value": { "verb": "update", "object_id": "10211885744794461" } } ], "id": "10210299214172187", "uid": "10210299214172187" } ], "object": "user" } 

Contenido de la carga

Las cargas incluirán un objeto que describirá el cambio. Al configurar el producto Webhooks, puedes indicar si las cargas solo deben incluir los nombres de los campos modificados o si deben incluir también los nuevos valores.

Damos formato JSON a todas las cargas para que puedas analizarlas con paquetes o métodos de análisis JSON comunes.

No almacenamos los datos de notificaciones de eventos de webhook que te enviamos. Por lo tanto, debes asegurarte de capturar y almacenar todo el contenido de carga que quieras conservar.

La mayoría de las cargas incluyen las siguientes propiedades comunes, pero el contenido y la estructura de cada carga varía según los campos del objeto a los que estés suscrito. Consulta la documentación de referencia de cada objeto para ver los campos que incluirá.
Propiedad 	Descripción 	Tipo

object
	

El tipo de objeto (por ejemplo, user, page, etc.)
	

string

entry
	

Una matriz que incluye un objeto que describe los cambios. Es posible agrupar por lotes varios cambios de diferentes objetos que son del mismo tipo.
	

array

id
	

El identificador del objeto
	

string

changed_fields
	

Una matriz de cadenas que indican los nombres de los campos que se modificaron. Solo se incluye si desactivaste el parámetro Incluir valores al configurar el producto Webhooks en el panel de apps de tu app.
	

array

changes
	

Una matriz que incluye un objeto que describe los campos modificados y sus nuevos valores. Solo se incluye si activaste el parámetro Incluir valores al configurar el producto Webhooks en el panel de apps de tu app.
	

array

time
	

Una marca de tiempo de UNIX que indica el momento en que se envió la notificación del evento (no el momento en que se produjo el cambio que disparó la notificación).
	

int
Validación de cargas

Firmamos todas las cargas de la notificación de eventos con una firma SHA256 e incluimos la firma en el encabezado X-Hub-Signature-256 de la solicitud, precedido por sha256=. No es obligatorio que valides la carga, pero conviene hacerlo.

Para validar la carga:

    Genera una firma SHA256 con la carga y con la clave secreta de la app.
    Compara tu firma con la del encabezado X-Hub-Signature-256 (todo lo que aparece después de sha256=). Si las firmas coinciden, la carga es genuina.

Ten en cuenta que generamos la firma usando una versión unicode con escape de la carga, con dígitos hexadecimales en minúsculas. Si solamente realizas el cálculo en relación con los bytes descodificados, obtendrás una firma diferente. Por ejemplo, la cadena äöå se debe escapar de la siguiente manera: \u00e4\u00f6\u00e5.
Respuesta a notificaciones de eventos

Tu punto de conexión debe responder a todas las notificaciones de eventos con 200 OK HTTPS.
Frecuencia

Las notificaciones de eventos se recopilan y se envían en un lote de hasta 1.000 actualizaciones como máximo. Sin embargo, los lotes no siempre funcionan, así que asegúrate de que los servidores puedan administrar cada webhook de manera individual.

Si falla alguna actualización enviada a tu servidor, volveremos a intentar la operación inmediatamente y, después, unas cuantas veces más, con una frecuencia cada vez menor, durante las siguientes 36 horas. Tu servidor deberá manejar la deduplicación en esos casos. Después de 36 horas, se descartarán las respuestas que no se hayan aceptado.

Nota: La frecuencia con la que se envían las notificaciones de eventos de Messenger es diferente. Consulta la documentación sobre los webhooks de la plataforma de Messenger para obtener más información.
Configurar el producto Webhooks

Una vez que el punto de conexión o la app de ejemplo estén listos, usa el panel de apps de tu app para agregar y configurar el producto Webhooks. También puedes hacer esto de manera programática mediante el punto de conexión /{app-id}/subscriptions para todos los webhooks, a excepción de Instagram.

En este ejemplo, utilizaremos el panel para configurar un webhook que se suscribe a cualquier cambio en las fotos de cualquiera de los usuarios de tu app.

    En el panel de apps, ve a Productos > Webhooks, selecciona Usuario en el menú desplegable y, a continuación, haz clic en Suscribirse a este objeto.
    Selección del objeto del usuario.

    Ingresa la URL del punto de conexión en el campo URL de devolución de llamada y una cadena en el campo Token de verificación. Incluiremos esta cadena en todas las solicitudes de verificación. Si usas una de nuestras apps de ejemplo, debe ser la misma cadena que usaste para la variable de configuración TOKEN.
    Si quieres que las cargas de notificación del evento incluyan los nombres de los campos que cambiaron además de los nuevos valores, define la opción Incluir valores en Sí.

https://developers.facebook.com/docs/graph-api/webhooks/getting-started
Validación de cargas

Firmamos todas las cargas de la notificación de eventos con una firma SHA256 e incluimos la firma en el encabezado X-Hub-Signature-256 de la solicitud, precedido por sha256=. No es obligatorio que valides la carga, pero conviene hacerlo.

Para validar la carga:

    Genera una firma SHA256 con la carga y con la clave secreta de la app.
    Compara tu firma con la del encabezado X-Hub-Signature-256 (todo lo que aparece después de sha256=). Si las firmas coinciden, la carga es genuina.

Ten en cuenta que generamos la firma usando una versión unicode con escape de la carga, con dígitos hexadecimales en minúsculas. Si solamente realizas el cálculo en relación con los bytes descodificados, obtendrás una firma diferente. Por ejemplo, la cadena äöå se debe escapar de la siguiente manera: \u00e4\u00f6\u00e5.
https://developers.facebook.com/docs/whatsapp/cloud-api/webhooks/components


Para marcarlos como leído
curl -X POST https://graph.facebook.com/v13.0/PHONE_NUMBER_ID/messages
-H 'Content-Type: application/json' 
-H 'Authorization: Bearer ACCESS_TOKEN'
-d '{
  "messaging_product": "whatsapp",
  "status": "read",
  "message_id": "MESSAGE_ID"
}'

{
  "success": true
}
GENERICO << ETX
  {
  "object": "whatsapp_business_account",
  "entry": [{
      "id": "WHATSAPP_BUSINESS_ACCOUNT_ID",
      "changes": [{
          "value": {
              "messaging_product": "whatsapp",
              "metadata": {
                  "display_phone_number": "PHONE_NUMBER",
                  "phone_number_id": "PHONE_NUMBER_ID"
              },
              # specific Webhooks payload
          },
          "field": "messages" #indica qué tipo de información se ha envíado
        }]
    }]
  }
  ETX

En esta página

Plataforma de WhatsApp Business
Messages

You can use the WhatsApp Business Platform to send text messages, media/documents, and message templates to your customers. You should use the following endpoints to send messages:

    On-Premises API /messages endpoint
    Cloud API /messages endpoint

This page provides an overview of how messages work on the WhatsApp Business Platform.
Using the Platform

Currently, we support sending two types of messages:
Business-Initiated Conversations

At any time, you can send business-initiated messages to customers who have opted-in. Throughout the documentation, these messages are also called notifications, message templates, or templated messages. When sending business-initiated messages, you are required to use a pre-approved message template, which can be text-based, media-based, or interactive.

For more information, see:

    On-Premises API: Sending Message Templates.
    Cloud API: Sending Text-Based Message Templates, Media-Based Message Templates, and Interactive Message Templates.

Businesses are charged per conversations, which includes all messages delivered in a 24 hour session. See Conversation-Based Pricing for information.
Scaling Business-Initiated Conversations

After completing Embedded Signup or the “on behalf of” (OBO) onboarding processes, businesses are immediately able to send business-initiated conversations to 50 unique customers in a rolling 24-hour period.

Businesses must initiate Business Verification when they are ready to scale business-initiated conversations, add additional phone numbers, or request to become an Official Business Account. When a business hits the limits, they can start the business verification process in the Business Manager by going to the Security Center. Visit Verify Your Business in Business Manager for more details.

Once approved, businesses can send business initiated conversations to 1K unique customers and increase based on our messaging limits upgrade requirements.
Read Receipts

Businesses can set up read receipts and customers can elect to send read receipts back. If the customer opts out of sending read receipts, the business will only be able to see that the message was delivered. For more information, see:

    On-Premises API: Marking Messages as Read
    Cloud API: Marking Messages as Read

Message Types

You can send the following message types using the platform:

    Text messages
    Media messages: image, video, and audio messages.
    Contact messages
    Location messages
    Interactive messages: List messages, Reply button messages, and Single and Multi Product Messages.
    Message templates

Message Status

For each message your business sends, you will receive a notification about the status of the message. In the table below, click the arrow in the left column for the WhatsApp App equivalent to each status, if available.
Name	Description

deleted
	

A message send by the user was deleted by the user. Upon receiving this notification, you should ensure that the message is deleted from your system if it was downloaded from the server.

delivered
	

A message sent by your business was delivered to the user's device.

failed
	

A message sent by your business failed to send. A reason for the failure will be included in the callback. Check the error message documentation for help debugging:

    On-Premises API Errors
    Cloud API Error Codes and Troubleshooting

read
	

A message sent by your business was read by the user. read notifications are only available for users that have read receipts enabled. For users that do not have it enabled, you only receive the delivered notification.

sent
	

A message sent by your business is in transit within our systems.

For On-Premises API users: To receive notifications for sent messages, set the sent_status setting to true in the application settings. The sent status notification is disabled by default.

warning
	

A message your business sent contains an item in a catalog that is not available or does not exist.
