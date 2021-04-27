# Occamy Manycore System

Based on the Manticore architecture.

## Elaboration

To do elaboration using VCS:

```
make bin/occamy_top.vcs
```

## Notes

All cores of the system will _always_ boot from base of ROM. Appropriate SW
needs to be placed there to handle hart bring-up.
