# Utilities

## Index

```@index
Pages = ["utilities.md"]
```

## Loss Functions

Loss Functions Objects take 2 forms of inputs:

  1. $\hat{y}$ and $y$ where $\hat{y}$ is the predicted output and $y$ is the target output.
  2. `model`, `ps`, `st`, `(x, y)` where `model` is the model, `ps` are the parameters,
     `st` are the states and `(x, y)` are the input and target pair. Then it returns the
     loss, updated states, and an empty named tuple. This makes them compatible with the
     [Experimental Training API](@ref Training-API).

!!! warning

    When using ChainRules.jl compatible AD (like Zygote), we only compute the gradients
    wrt the inputs and drop any gradients wrt the targets.

```@docs
GenericLossFunction
BinaryCrossEntropyLoss
BinaryFocalLoss
CrossEntropyLoss
DiceCoeffLoss
FocalLoss
HingeLoss
HuberLoss
KLDivergenceLoss
MAELoss
MSELoss
MSLELoss
PoissonLoss
SiameseContrastiveLoss
SquaredHingeLoss
```

## Weight Initialization

!!! warning

    For API documentation on Initialization check out the
    [WeightInitializers.jl](@ref WeightInitializers-API)

## Miscellaneous Utilities

```@docs
Lux.foldl_init
Lux.istraining
Lux.multigate
Lux.xlogy
Lux.xlogx
```

## Updating Floating Point Precision

By default, Lux uses Float32 for all parameters and states. To update the precision
simply pass the parameters / states / arrays into one of the following functions.

```@docs
Lux.f16
Lux.f32
Lux.f64
```

## Stateful Layer

```@docs
StatefulLuxLayer
```

## Compact Layer

```@docs
@compact
```

## Truncated Stacktraces (Deprecated)

```@docs
Lux.disable_stacktrace_truncation!
```

## Device Management / Data Transfer (Deprecated)

```@docs
Lux.cpu
Lux.gpu
```

!!! warning

    For detailed API documentation on Data Transfer check out the
    [LuxDeviceUtils.jl](@ref LuxDeviceUtils-API)
