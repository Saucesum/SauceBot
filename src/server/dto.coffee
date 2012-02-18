# SauceBot Data Transfer Object

DTOs = [
    'ArrayDTO',
    'HashDTO',
    'ConfigDTO',
    'EnumDTO'
]

for DTO in DTOs
    exports[DTO] = require('./dto/' + DTO)[DTO]
