\documentclass{article}

%include lhs2TeX.fmt
%include lhs2TeX.sty
%include polycode.fmt
%include agda.fmt

\usepackage{textgreek}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{graphicx}
\usepackage{fancyvrb}
\usepackage{hyperref}
\usepackage{color}


\usepackage{tikz}

\usetikzlibrary{cd}
\usetikzlibrary{arrows, matrix, trees}
\tikzcdset{every diagram/.style={column sep=4cm, row sep=4cm}}

\begin{document}

\title{}
\author{}

%if False
\begin{code}
module Heap where

open import Level using () renaming (zero to lzero)
open import Data.Unit
open import Data.Empty
open import Data.Nat
open import Data.Bool
open import Data.Product
open import Data.List as L
open import Data.Vec as V
open import Function
open import Relation.Binary.Indexed
open import Relation.Binary using (DecTotalOrder)
open import Relation.Nullary.Core
open import Relation.Binary.PropositionalEquality as PropEq
open import Relation.Binary.PropositionalEquality.Core
import Relation.Binary.EqReasoning as EqR
\end{code}
%endif

\section{Trees}

\begin{code}
data Tree A : Bool × Bool → Set where
  ⟨⟩  : Tree A (false , false)
  ⟨_⟩ : A → Tree A (true , true)
  _↙_ : ∀ {lx rx ry} → Tree A (lx , rx) → Tree A (true , ry) → Tree A (false , ry)
  _↘_ : ∀ {lx ly ry} → Tree A (lx , true) → Tree A (ly , ry) → Tree A (lx , false)

data _≈h_ {A : Set} : Rel (Tree A) lzero where
  nil            :                              ⟨⟩ ≈h ⟨⟩
  singleton           : ∀ {a} → a ≡ a →           ⟨ a ⟩ ≈h ⟨ a ⟩
  left           : ∀ {lx rx ry a b}
    → a ≡ a → b ≡ b
      → (_↙_ {lx = lx}{rx = rx}{ry = ry} a b)      ≈h (a ↙ b)
  right          : ∀ {lx ly ry a b}
    → a ≡ a → b ≡ b
      → (_↘_ {lx = lx}{ly = ly}{ry = ry} a b)      ≈h (a ↘ b)
  left-identity  : ∀ {ry a} → (_↙_ {ry = ry} ⟨⟩ a) ≈h a
  right-identity : ∀ {lx a} → (_↘_ {lx = lx} a ⟨⟩) ≈h a
  assoc          : ∀ {lx rx ly ry a b c} →
    (_↙_ {lx = lx}{rx = rx} a
      (_↘_ {ly = ly} {ry = ry} b c))               ≈h ((a ↙ b) ↘ c)

hsym : (A : Set) → Symmetric (Tree A) _≈h_
hsym A {.false , .false} {.false , .false} nil = nil
hsym A {.true , .true} {.true , .true} (singleton x) = singleton refl
hsym A {.false , proj₂} {.false , .proj₂} (left x x₁) = left refl refl
hsym A {proj₁ , .false} {.proj₁ , .false} (right x x₁) = right refl refl
hsym A {.false , .true} {.true , .true} {j = ⟨ x ⟩} left-identity = {!!}
hsym A {.false , .false} {.true , .false} {j = j ↘ j₁} left-identity = {!!}
hsym A {proj₁ , .false} {.proj₁ , .true} right-identity = {!!}
hsym A {.false , .false} {.false , .false} assoc = {!!}

htrans : (A : Set) → Transitive (Tree A) _≈h_
htrans A x y = {!!}

HTreeS : Set → Setoid (Bool × Bool) lzero lzero
HTreeS A = record
  { Carrier = Tree A
  ; _≈_ = _≈h_
  ; isEquivalence = record
    { refl = λ { {x = ⟨⟩}    → nil
               ; {x = ⟨ x ⟩} → singleton refl
               ; {x = x ↙ y} → left refl refl
               ; {x = x ↘ y} → right refl refl }
    ; sym = hsym A
    ; trans = htrans A } }


HTree : Set → Set
HTree A = Σ (Bool × Bool) (λ zz → Tree A zz)

_↙'_ :  ∀ {A} → HTree A → HTree A → HTree A
(aa , a) ↙' ((true , bb) , b) = (false , bb) , a ↙ b
(aa , a) ↙' ((false , bb) , b) = (false , bb) , b -- dummy

_↘'_ :  ∀ {A} → HTree A → HTree A → HTree A
((aa , true) , a) ↘' (bb , b) = (aa , false) , a ↘ b
((aa , false) , a) ↘' (bb , b) = (aa , false) , a -- dummy
\end{code}

\section{Maps and reduces}

\begin{code}
map-tree : ∀ {lr A B} → (A → B) → Tree A lr → Tree B lr
map-tree f ⟨⟩ = ⟨⟩
map-tree f ⟨ x ⟩ = ⟨ f x ⟩
map-tree f (x ↙ y) = map-tree f x ↙ map-tree f y
map-tree f (x ↘ y) = map-tree f x ↘ map-tree f y

record Reducer A : Set where
  field
    ⊕ : A → A → A
    ⊗ : A → A → A
    e : A

reduce-tree : ∀ {A lr} → Reducer A → Tree A lr → A
reduce-tree r ⟨⟩ = Reducer.e r
reduce-tree r ⟨ x ⟩ = x
reduce-tree r (x ↙ y) = Reducer.⊕ r (reduce-tree r x) (reduce-tree r y)
reduce-tree r (x ↘ y) = Reducer.⊗ r (reduce-tree r x) (reduce-tree r y)
\end{code}

\subsection{Examples}

\begin{code}
_<<_   : ∀ {A : Set} → A → A → A
a << b = a

_>>_   : ∀ {A : Set} → A → A → A
a >> b = b

label : ∀ {A lr} → A → Tree A lr → A
label def = reduce-tree (record { ⊕ = _>>_ ; ⊗ = _<<_ ; e = def })

inorder : ∀ {A lr} → Tree A lr → List A
inorder = reduce-tree (record { ⊕ = L._++_ ; ⊗ = L._++_ ; e = [] }) ∘ map-tree (L.[_])

size : ∀ {A lr} → Tree A lr → ℕ
size = reduce-tree (record { ⊕ = _+_ ; ⊗ = _+_ ; e = 0 }) ∘ map-tree (λ x → 1)

member : ∀ {A lr} → A → Tree A lr → Bool
member x = reduce-tree (record { ⊕ = _∧_ ; ⊗ = _∧_ ; e = true }) ∘ map-tree {!!}

depth : ∀ {A lr} → Tree A lr → ℕ
depth = reduce-tree (record { ⊕ = λ a b → suc a ⊔ b ; ⊗ = λ b a → suc a ⊔ b ; e = 0 }) ∘ map-tree (λ x → 1)

heaporder : ∀ {A lr} → Tree A lr → List A
heaporder = reduce-tree (record { ⊕ = {!!} ; ⊗ = {!!} ; e = [] }) ∘ map-tree (L.[_])
\end{code}

\section{Accumulations}

\begin{code}
up : ∀ {A aa} → Reducer A → A → Tree A aa → Tree A aa
up r d ⟨⟩ = ⟨⟩
up r d ⟨ a ⟩ = ⟨ a ⟩
up r d (x ↙ ⟨ a ⟩) = up r d x ↙ ⟨ Reducer.⊕ r (label d (up r d x)) a ⟩
up r d (x ↙ (⟨ a ⟩ ↘ y)) = up r d x ↙ (⟨ Reducer.⊕ r (label d (up r d x)) (Reducer.⊗ r a (label d (up r d y))) ⟩ ↘ up r d y)
up r d (⟨ a ⟩ ↘ y) = ⟨ Reducer.⊗ r a (label d (up r d y)) ⟩ ↘ up r d y
up r d ((x ↙ ⟨ a ⟩) ↘ y) = up r d x ↙ (⟨ Reducer.⊕ r (label d (up r d x)) (Reducer.⊗ r a (label d (up r d y))) ⟩ ↘ up r d y)

subtrees : ∀ {lr A} → A → Tree A lr → Tree (HTree A) lr
subtrees d = up (record { ⊕ = _↙'_ ; ⊗ = _↘'_ ; e = (true , true) , ⟨ d ⟩ }) ((true , true) , ⟨ d ⟩) ∘ map-tree (λ x → (true , true) , ⟨ x ⟩)

subtrees-inverse : ∀ {A}{d : A}{x} → map-tree (label d ∘ proj₂) (subtrees d x) ≡ x
subtrees-inverse = {!!}

module AccumLemma {A : Set} where

  accum-lemma : ∀ {A}{d : A}{r}{x} → up r d x ≡ (map-tree (reduce-tree r ∘ proj₂) ∘ subtrees d) x
  accum-lemma {x = ⟨⟩} = refl
  accum-lemma {x = ⟨⟩ ↙ (⟨ a ⟩ ↘ ⟨⟩)} = {!!}
  accum-lemma {x = ⟨⟩ ↙ (⟨ a ⟩ ↘ ⟨ x ⟩)}  = {!!}
  accum-lemma {x = ⟨⟩ ↙ (⟨ a ⟩ ↘ (x ↙ y))} = {!!}
  accum-lemma {x = ⟨⟩ ↙ (⟨ a ⟩ ↘ (x ↘ y))} = {!!}
  accum-lemma {x = ⟨ x ⟩ ↙ (⟨ a ⟩ ↘ y)} = {!!}
  accum-lemma {x = (x ↙ x₁) ↙ (⟨ a ⟩ ↘ x₃)} = {!!}
  accum-lemma {x = (x ↘ x₁) ↙ (⟨ a ⟩ ↘ x₃)} = {!!}
  accum-lemma {x = x ↘ x₁} = {!!}
\end{code}

\section{Building a heap}

\begin{code}
module HeapOrder {ℓ₁ ℓ₂}{ord : DecTotalOrder lzero ℓ₁ ℓ₂} where
  open Relation.Binary.DecTotalOrder ord renaming (_≤_ to _⊑_; _≤?_ to _⊑?_; Carrier to A)

  -- doesn't termination check because the checker doesn't see associativity well
  -- playing with parentheses placement puts termination errors into different places

  _⊕h'_ : ∀ {xx yy} → Tree A xx → Tree A yy → Σ (Bool × Bool) (λ zz → Tree A zz)

  -- left and right identities
  _⊕h'_ {false , false} {yy} ⟨⟩ y  = yy , y
  _⊕h'_ {xx} {false , false} x ⟨⟩  = xx , x

  -- juicy meat
  ((x ↙ ⟨ a ⟩) ↘ y) ⊕h' ((u ↙ ⟨ b ⟩) ↘ v) with a ⊑? b
  ... | yes p                         = ((false , false) , (x ↙ ⟨ a ⟩) ↘ proj₂ (y ⊕h' ((u ↙ ⟨ b ⟩) ↘ v)))
  ... | no ¬p                         = ((false , false) , proj₂ (((x ↙ ⟨ a ⟩) ↘ y) ⊕h' u) ↙ (⟨ b ⟩ ↘ v))
  ((x ↙ ⟨ a ⟩) ↘ y) ⊕h' (u ↙ (⟨ b ⟩ ↘ v)) with a ⊑? b
  ... | yes p                         = ((false , false) , (x ↙ ⟨ a ⟩) ↘ proj₂ (y ⊕h' ((u ↙ ⟨ b ⟩) ↘ v)))
  ... | no ¬p                         = ((false , false) , proj₂ (((x ↙ ⟨ a ⟩) ↘ y) ⊕h' u) ↙ (⟨ b ⟩ ↘ v))
  (x ↙ (⟨ a ⟩ ↘ y)) ⊕h' ((u ↙ ⟨ b ⟩) ↘ v) with a ⊑? b
  ... | yes p                         = ((false , false) , (x ↙ ⟨ a ⟩) ↘ proj₂ (y ⊕h' ((u ↙ ⟨ b ⟩) ↘ v)))
  ... | no ¬p                         = ((false , false) , proj₂ (((x ↙ ⟨ a ⟩) ↘ y) ⊕h' u) ↙ (⟨ b ⟩ ↘ v))
  (x ↙ (⟨ a ⟩ ↘ y)) ⊕h' (u ↙ (⟨ b ⟩ ↘ v)) with a ⊑? b
  ... | yes p                         = ((false , false) , (x ↙ ⟨ a ⟩) ↘ proj₂ (y ⊕h' ((u ↙ ⟨ b ⟩) ↘ v)))
  ... | no ¬p                         = ((false , false) , proj₂ (((x ↙ ⟨ a ⟩) ↘ y) ⊕h' u) ↙ (⟨ b ⟩ ↘ v))

  -- boring cruft
  ⟨ a ⟩             ⊕h' ⟨ b ⟩             = ((⟨⟩ ↙ ⟨ a ⟩) ↘ ⟨⟩) ⊕h' ((⟨⟩ ↙ ⟨ b ⟩) ↘ ⟨⟩)
  ⟨ a ⟩             ⊕h' (u ↙ ⟨ b ⟩)       = ((⟨⟩ ↙ ⟨ a ⟩) ↘ ⟨⟩) ⊕h' ((u ↙ ⟨ b ⟩) ↘ ⟨⟩)
  ⟨ a ⟩             ⊕h' (u ↙ (⟨ b ⟩ ↘ v)) = ((⟨⟩ ↙ ⟨ a ⟩) ↘ ⟨⟩) ⊕h' ((u ↙ ⟨ b ⟩) ↘ v)
  ⟨ a ⟩             ⊕h' (⟨ b ⟩ ↘ v)       = ((⟨⟩ ↙ ⟨ a ⟩) ↘ ⟨⟩) ⊕h' ((⟨⟩ ↙ ⟨ b ⟩) ↘ v)
  ⟨ a ⟩             ⊕h' ((u ↙ ⟨ b ⟩) ↘ v) = ((⟨⟩ ↙ ⟨ a ⟩) ↘ ⟨⟩) ⊕h' ((u ↙ ⟨ b ⟩) ↘ v)

  (x ↙ ⟨ a ⟩)       ⊕h' ⟨ b ⟩             = ((x ↙ ⟨ a ⟩) ↘ ⟨⟩) ⊕h' ((⟨⟩ ↙ ⟨ b ⟩) ↘ ⟨⟩)
  (x ↙ ⟨ a ⟩)       ⊕h' (u ↙ ⟨ b ⟩)       = ((x ↙ ⟨ a ⟩) ↘ ⟨⟩) ⊕h' ((u ↙ ⟨ b ⟩) ↘ ⟨⟩)
  (x ↙ ⟨ a ⟩)       ⊕h' (⟨ b ⟩ ↘ v)       = ((x ↙ ⟨ a ⟩) ↘ ⟨⟩) ⊕h' ((⟨⟩ ↙ ⟨ b ⟩) ↘ v)
  (x ↙ ⟨ a ⟩)       ⊕h' (u ↙ (⟨ b ⟩ ↘ v)) = ((x ↙ ⟨ a ⟩) ↘ ⟨⟩) ⊕h' ((u ↙ ⟨ b ⟩) ↘ v)
  (x ↙ ⟨ a ⟩)       ⊕h' ((u ↙ ⟨ b ⟩) ↘ v) = ((x ↙ ⟨ a ⟩) ↘ ⟨⟩) ⊕h' ((u ↙ ⟨ b ⟩) ↘ v)
  
  (⟨ a ⟩ ↘ y)       ⊕h' ⟨ b ⟩             = ((⟨⟩ ↙ ⟨ a ⟩) ↘ y) ⊕h' ((⟨⟩ ↙ ⟨ b ⟩) ↘ ⟨⟩)
  (⟨ a ⟩ ↘ y)       ⊕h' (⟨ b ⟩ ↘ v)       = ((⟨⟩ ↙ ⟨ a ⟩) ↘ y) ⊕h' ((⟨⟩ ↙ ⟨ b ⟩) ↘ v)
  (⟨ a ⟩ ↘ y)       ⊕h' (u ↙ ⟨ b ⟩)       = ((⟨⟩ ↙ ⟨ a ⟩) ↘ y) ⊕h' ((u ↙ ⟨ b ⟩) ↘ ⟨⟩)
  (⟨ a ⟩ ↘ y)       ⊕h' (u ↙ (⟨ b ⟩ ↘ v)) = ((⟨⟩ ↙ ⟨ a ⟩) ↘ y) ⊕h' ((u ↙ ⟨ b ⟩) ↘ v)
  (⟨ a ⟩ ↘ y)       ⊕h' ((u ↙ ⟨ b ⟩) ↘ v) = ((⟨⟩ ↙ ⟨ a ⟩) ↘ y) ⊕h' ((u ↙ ⟨ b ⟩) ↘ v)

  ((x ↙ ⟨ a ⟩) ↘ y) ⊕h' ⟨ b ⟩       = ((x ↙ ⟨ a ⟩) ↘ y) ⊕h' ((⟨⟩ ↙ ⟨ b ⟩) ↘ ⟨⟩)
  (x ↙ (⟨ a ⟩ ↘ y)) ⊕h' ⟨ b ⟩       = ((x ↙ ⟨ a ⟩) ↘ y) ⊕h' ((⟨⟩ ↙ ⟨ b ⟩) ↘ ⟨⟩)
  ((x ↙ ⟨ a ⟩) ↘ y) ⊕h' (u ↙ ⟨ b ⟩) = ((x ↙ ⟨ a ⟩) ↘ y) ⊕h' ((u ↙ ⟨ b ⟩) ↘ ⟨⟩)
  ((x ↙ ⟨ a ⟩) ↘ y) ⊕h' (⟨ b ⟩ ↘ v) = ((x ↙ ⟨ a ⟩) ↘ y) ⊕h' ((⟨⟩ ↙ ⟨ b ⟩) ↘ v)
  (x ↙ (⟨ a ⟩ ↘ y)) ⊕h' (u ↙ ⟨ b ⟩) = ((x ↙ ⟨ a ⟩) ↘ y) ⊕h' ((u ↙ ⟨ b ⟩) ↘ ⟨⟩)
  (x ↙ (⟨ a ⟩ ↘ y)) ⊕h' (⟨ b ⟩ ↘ v) = ((x ↙ ⟨ a ⟩) ↘ y) ⊕h' ((⟨⟩ ↙ ⟨ b ⟩) ↘ v)

  _⊕h_ : HTree A → HTree A → HTree A
  (proj₁ , proj₂) ⊕h (proj₃ , proj₄) = proj₂ ⊕h' proj₄

  heap : ∀ {n} → (s : Vec A (suc n)) → HTree A
  heap = V.foldl₁ _⊕h_ ∘ V.map (λ x → (true , true) , ⟨ x ⟩)

  heap-inverse : ∀ {n}{x : Vec A (suc n)} → inorder {A} (proj₂ (heap x)) ≡ toList x
  heap-inverse = {!!}

  heaptree : ∀ {lr} → Tree A lr → Bool
  heaptree xs = nondec (heaporder xs)
    where
      -- is that available from the stdlib?
      nondec : List A → Bool
      nondec (x ∷ y ∷ xs) with x ⊑? y
      ... | yes _ = nondec xs
      ... | no  _ = false
      nondec _ = true

  heap-tree : ∀ {n}{x : Vec A (suc n)} → heaptree (proj₂ (heap x)) ≡ true
  heap-tree = {!!}

  heaptree' : ∀ {lr} → Tree A lr → Bool
  heaptree' (x ↙ y) with  label {!!} y ⊑? label {!!} x
  ... | yes _ = heaptree' x ∧ heaptree' y
  ... | no  _ = false
  heaptree' (x ↘ y) with label {!!} x ⊑? label {!!} y
  ... | yes _ = heaptree' x ∧ heaptree' y
  ... | no  _ = false
  heaptree' _ = true

  heaptree'-equiv : ∀ {lr}{x : Tree A lr} → heaptree' x ≡ heaptree x
  heaptree'-equiv = {!!}
\end{code}

\section{Solution as a left reduction}

\begin{code}

\end{code}

\section{Prefix and suffix}

\begin{code}

\end{code}

\section{A linear algorithm}

\begin{code}

\end{code}

\section{Application}

\begin{code}

\end{code}


\end{document}
