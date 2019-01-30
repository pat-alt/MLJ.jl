module TestEnsembles

# using Revise
using Test
using MLJ
using DataFrames
using CategoricalArrays
using Distributions


## WRAPPED ENSEMBLES OF FITRESULTS

# target is :deterministic :multiclass :univariate:
atom = DeterministicConstantClassifier(target_type=Char)
L = ['a', 'b', 'j']
ensemble = [('a', L), ('j', L), ('j', L), ('b', L)]
n=length(ensemble)
weights = fill(1/n, n) # ignored by predict below
wens = MLJ.WrappedEnsemble(atom, ensemble)
X = DataFrame(rand(3,5))
@test predict(wens, weights, X) == categorical(['j','j','j'])

# target is :deterministic :continuous :univariate:
atom = DeterministicConstantRegressor()
ensemble = Float64[4, 7, 4, 4]
weights = [0.1, 0.5, 0.2, 0.2]
wens = MLJ.WrappedEnsemble(atom, ensemble)
@test predict(wens, weights, X) ≈ [5.5, 5.5, 5.5]

# target is :probabilistic :multiclass :univariate:
atom = ConstantClassifier(target_type=Char)
L = ['a', 'b', 'j']
d1 = UnivariateNominal(L, [0.1, 0.2, 0.7])
d2 = UnivariateNominal(L, [0.2, 0.3, 0.5])
ensemble = [d2,  d1, d2, d2]
weights = [0.1, 0.5, 0.2, 0.2]
wens = MLJ.WrappedEnsemble(atom, ensemble)
X = DataFrame(rand(2,5))
d = predict(wens, weights, X)[1]
@test pdf(d, 'a') ≈ 0.15
@test pdf(d, 'b') ≈ 0.25
@test pdf(d, 'j') ≈ 0.6

# target is :probabilistic :continuous :univariate:
atom = ConstantRegressor(target_type=Float64)
d1 = Distributions.Normal(1, 2)
d2 = Distributions.Normal(3, 4)
ensemble = [d2,  d1, d2, d2]
weights = [0.1, 0.5, 0.2, 0.2]
wens = MLJ.WrappedEnsemble(atom, ensemble)
X = DataFrame(rand(2,5))
d = predict(wens, weights, X)[1]


## ENSEMBLE MODEL

# target is :deterministic :multiclass :univariate:
atom=DeterministicConstantClassifier(target_type=Char)
X = DataFrame(ones(5,3))
y = categorical(collect("asdfa"))
train, test = partition(1:length(y), 0.8);
ensemble_model = DeterministicEnsembleModel(atom=atom)
ensemble_model.n = 10
fitresult, cache, report = MLJ.fit(ensemble_model, 1, MLJ.coerce(ensemble_model, X), y)
predict(ensemble_model, fitresult, X[test,:])
weights = rand(10)
ensemble_model.weights = weights
predict(ensemble_model, fitresult, X[test,:])

# target is :deterministic :continuous :univariate:
atom = DeterministicConstantRegressor(target_type=Float64)
X = DataFrame(ones(5,3))
y = Float64[1.0, 2.0, 1.0, 1.0, 1.0]
train, test = partition(1:length(y), 0.8);
ensemble_model = DeterministicEnsembleModel(atom=atom)
ensemble_model.n = 10
fitresult, cache, report = MLJ.fit(ensemble_model, 1, MLJ.coerce(ensemble_model, X), y)
@test reduce(* , [x ≈ 1.0 || x ≈ 1.25 for x in fitresult.ensemble])
predict(ensemble_model, fitresult, X[test,:])
ensemble_model.bagging_fraction = 1.0
fitresult, cache, report = MLJ.fit(ensemble_model, 1, MLJ.coerce(ensemble_model, X), y)
@test unique(fitresult.ensemble) ≈ [1.2]
predict(ensemble_model, fitresult, X[test,:])
weights = rand(10)
ensemble_model.weights = weights
predict(ensemble_model, fitresult, X[test,:])

# target is :probabilistic :multiclass :univariate:
atom = ConstantClassifier(target_type=Char)
X = DataFrame(ones(5,3))
y = categorical(collect("asdfa"))
train, test = partition(1:length(y), 0.8);
ensemble_model = ProbabilisticEnsembleModel(atom=atom)
ensemble_model.n = 10
fitresult, cache, report = MLJ.fit(ensemble_model, 1, MLJ.coerce(ensemble_model, X), y)
fitresult.ensemble
predict(ensemble_model, fitresult, X[test,:])
ensemble_model.bagging_fraction = 1.0
fitresult, cache, report = MLJ.fit(ensemble_model, 1, MLJ.coerce(ensemble_model, X), y)
fitresult.ensemble
d = predict(ensemble_model, fitresult, X[test,:])[1]
@test pdf(d, 'a') ≈ 2/5
@test pdf(d, 's') ≈ 1/5
@test pdf(d, 'd') ≈ 1/5
@test pdf(d, 'f') ≈ 1/5
weights = rand(10)
ensemble_model.weights = weights
predict(ensemble_model, fitresult, X[test,:])

# target is :probabilistic :continuous :univariate:
atom = ConstantRegressor(target_type=Float64)
X = DataFrame(ones(5,3))
y = Float64[1.0, 2.0, 2.0, 1.0, 1.0]
train, test = partition(1:length(y), 0.8);
ensemble_model = ProbabilisticEnsembleModel(atom=atom)
ensemble_model.n = 10
fitresult, cache, report = MLJ.fit(ensemble_model, 1, MLJ.coerce(ensemble_model, X), y)
d1 = fit(Distributions.Normal, [1,1,2,2])
d2 = fit(Distributions.Normal, [1,1,1,2])
# @test reduce(* , [d.μ ≈ d1.μ || d.μ ≈ d2.μ for d in fitresult.ensemble])
# @test reduce(* , [d.σ ≈ d1.σ || d.σ ≈ d2.σ for d in fitresult.ensemble])
d=predict(ensemble_model, fitresult, X[test,:])[1]
for dc in d.components
    @test pdf(dc, 1.52) ≈ pdf(d1, 1.52) || pdf(dc, 1.52) ≈ pdf(d2, 1.52)
end
ensemble_model.bagging_fraction = 1.0
fitresult, cache, report = MLJ.fit(ensemble_model, 1, MLJ.coerce(ensemble_model, X), y)
d = predict(ensemble_model, fitresult, X[test,:])[1]
d3 = fit(Distributions.Normal, y)
@test pdf(d, 1.52) ≈ pdf(d3, 1.52)
weights = rand(10)
ensemble_model.weights = weights
predict(ensemble_model, fitresult, X[test,:])

# test generic constructor:
@test EnsembleModel(atom=ConstantRegressor()) isa Probabilistic
@test EnsembleModel(atom=DeterministicConstantRegressor()) isa Deterministic


## MAHCINE TEST

X, y = datanow() # boston
atom = KNNRegressor(K=7)
ensemble_model = EnsembleModel(atom=atom)
ensemble = machine(ensemble_model, X, y)
train, test = partition(eachindex(y), 0.7)
fit!(ensemble, rows=train); length(ensemble.fitresult.ensemble)
ensemble_model.n = 15
fit!(ensemble);
@test length(ensemble.fitresult.ensemble) == 15
ensemble_model.n = 10
fit!(ensemble);
@test length(ensemble.fitresult.ensemble) == 10
@test !isnan(predict(ensemble, X[test,:])[1])


# old Koala tests
# # check that providing fixed seed gives identical predictions each
# # time if trees are deterministic:
# tree.max_features = 0
# ensemble_model.rng_seed = 1234
# fit!(ensemble, train);
# p1 = predict(ensemble, X, test[1:10])
# fit!(ensemble, train);
# p2 = predict(ensemble, X, test[1:10])
# @test p1 == p2

# tree.max_features = 4
# fit!(ensemble);
# ensemble_model.weight_regularization = 0.5
# fit_weights!(ensemble);
# display(ensemble.report[:normalized_weights])
# err(ensemble, test)
# fit!(ensemble, train, add=true);
# err(ensemble, test)
# u,v = weight_regularization_curve(ensemble, test, raw=false,
#                                   range=range(0, stop=1, length=21))
# UnicodePlots.lineplot(u,v)
# ensemble_model.weight_regularization = u[argmin(v)]
# fit_weights!(ensemble);
# err(ensemble, test)

end
true
