defmodule Parakeet.Game.Card do

  @type face :: :number | :jack | :queen | :king | :ace
  @type suit :: :hearts | :diamonds | :spades | :clubs

  @type t :: %__MODULE__{face: face(), suit: suit(), value: integer()}


  @derive Jason.Encoder
  defstruct [:face, :suit, :value]

  @faces [:ace, :king, :queen, :jack]
  def face?(card), do: card.face in @faces


  def get_value_down(%__MODULE__{value: 2}), do: 14
  def get_value_down(%__MODULE__{value: value}), do: value - 1
  def get_value_up(%__MODULE__{value: 14}), do: 2
  def get_value_up(%__MODULE__{value: value}), do: value + 1

  def challenge_chances(%__MODULE__{face: :jack}), do: 1
  def challenge_chances(%__MODULE__{face: :queen}), do: 2
  def challenge_chances(%__MODULE__{face: :king}), do: 3
  def challenge_chances(%__MODULE__{face: :ace}), do: 4
  def challenge_chances(%__MODULE__{}), do: nil
end
