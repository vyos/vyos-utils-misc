## Build VyOS iso in MAC

  `make build`

### Create crux based iso

  `os=jessie64 branch=crux make build`

### Custom build options

  `os=jessie64 branch=crux configureopt='--architecture amd64 --build-by richard@vyos.io' make build`

### Clean up VM

  `make clean`

### Purge build and clean

  `make purge`

### Dependencies

  - vagrant
  - virtualbox
  - rsync
