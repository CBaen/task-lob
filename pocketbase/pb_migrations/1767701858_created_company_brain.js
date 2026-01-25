/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "createRule": "",
    "deleteRule": "",
    "fields": [
      {
        "autogeneratePattern": "[a-z0-9]{15}",
        "hidden": false,
        "id": "text3208210256",
        "max": 15,
        "min": 15,
        "name": "id",
        "pattern": "^[a-z0-9]+$",
        "presentable": false,
        "primaryKey": true,
        "required": true,
        "system": true,
        "type": "text"
      },
      {
        "cascadeDelete": false,
        "collectionId": "pbc_2170078043",
        "hidden": false,
        "id": "relation2375286809",
        "maxSelect": 1,
        "minSelect": 0,
        "name": "workspace",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "relation"
      },
      {
        "hidden": false,
        "id": "select602749991",
        "maxSelect": 1,
        "name": "memory_type",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "select",
        "values": [
          "system",
          "person",
          "company",
          "product",
          "vocabulary",
          "routing"
        ]
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text2324736937",
        "max": 0,
        "min": 0,
        "name": "key",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": true,
        "system": false,
        "type": "text"
      },
      {
        "hidden": false,
        "id": "json494360628",
        "maxSize": 0,
        "name": "value",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "json"
      },
      {
        "hidden": false,
        "id": "number158830993",
        "max": 1,
        "min": 0,
        "name": "confidence",
        "onlyInt": false,
        "presentable": false,
        "required": false,
        "system": false,
        "type": "number"
      },
      {
        "hidden": false,
        "id": "number2177257276",
        "max": null,
        "min": null,
        "name": "times_confirmed",
        "onlyInt": false,
        "presentable": false,
        "required": false,
        "system": false,
        "type": "number"
      },
      {
        "hidden": false,
        "id": "number293484338",
        "max": null,
        "min": null,
        "name": "times_used",
        "onlyInt": false,
        "presentable": false,
        "required": false,
        "system": false,
        "type": "number"
      },
      {
        "hidden": false,
        "id": "date4016875332",
        "max": "",
        "min": "",
        "name": "last_used",
        "presentable": false,
        "required": false,
        "system": false,
        "type": "date"
      }
    ],
    "id": "pbc_486742421",
    "indexes": [],
    "listRule": "",
    "name": "company_brain",
    "system": false,
    "type": "base",
    "updateRule": "",
    "viewRule": ""
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_486742421");

  return app.delete(collection);
})
