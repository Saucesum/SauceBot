# SauceBot Data Transfer Object

DTOs = [
    'ArrayDTO',
    'HashDTO',
    'BucketDTO',
    'ConfigDTO',
    'EnumDTO'
]

for DTO in DTOs
    exports[DTO] = require('./dto/' + DTO)[DTO]
