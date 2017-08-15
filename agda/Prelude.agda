module Prelude where

-- STANDARD LIBRARY STUFF
open import Level public

open import Data.Bool public using (Bool; true; false; not; if_then_else_)
open import Data.Empty public using (⊥; ⊥-elim)
open import Data.Maybe public using (Maybe; just; nothing; maybe)
open import Data.Nat public using (ℕ)
open import Data.Product public using (Σ; proj₁; proj₂; Σ-syntax; ∃; ∄; _×_; _,_; ,_)
open import Data.Sum public using (_⊎_; inj₁; inj₂)
open import Data.Unit public using (⊤; tt)
open import Function public using (_∘_; _on_)
open import Relation.Nullary public using (¬_; Dec; yes; no)
open import Relation.Binary public
  using (Rel; Reflexive; Transitive; Symmetric; Antisymmetric; Decidable)

module Eq where open import Relation.Binary.PropositionalEquality public
open Eq public using (_≡_; refl)


-- MY STUFF
-- open import Cast public

Op : ∀{i} -> Set i -> Set i
Op A = A -> A -> A

Function : ∀{i j} -> Set i -> Set j -> Set _
Function A B = A -> B

it : ∀{i}{A : Set i} {{x : A}} -> A
it {{x}} = x

-- TODO: remove this once I think I've proved everything
postulate TODO : ∀{i}{A : Set i} -> A
