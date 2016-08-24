scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "Usa varias palabras, evita frases comunes"
      "No es necesario usar símbolos, números o letras mayúsculas"
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = 'Agrega una o dos palabras mas. Usa palabras poco comunes.'
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          'Filas de teclas son fáciles de adivinar'
        else
          'Patrones cortos son fáciles de adivinar'
        warning: warning
        suggestions: [
          'Usa un patrón de teclas más largo'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'Repeticiones como "aaa" son fáciles de adivinar'
        else
          'Repeticiones como "abcabcabc" son solo un poco mejores que "abc"'
        warning: warning
        suggestions: [
          'Evita repetir palabras y caracteres'
        ]

      when 'sequence'
        warning: "Secuencias como abc o 6543 son fáciles de adivinar"
        suggestions: [
          'Evita usar secuencias'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "Años recientes son fáciles de adivinar"
          suggestions: [
            'Evita usar años recientes'
            'Evita usar años relacionados contigo'
          ]

      when 'date'
        warning: "Las fechas son fáciles de adivinar"
        suggestions: [
          'Evita usar fechas y años relacionados contigo'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'Esta contraseña está dentro de las 10 más usadas'
        else if match.rank <= 100
          'Esta contraseña está dentro de las 100 más usadas'
        else
          'Esta es una contraseña muy común'
      else if match.guesses_log10 <= 4
        'Esta contraseña es muy parecida a las más comunes'
    else if match.dictionary_name == 'english'
      if is_sole_match
        'Una palabra es muy fácil de adivinar'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        'Nombres y apellidos son muy fáciles de adivinar por si solos'
      else
        'Nómbres y apellidos comunes son muy fáciles de adivinar'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "Usar mayúsculas no mejora mucho tu contraseña"
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "Todas mayúsculas es casi tan fácil de adivinar como en minúsculas"

    if match.reversed and match.token.length >= 4
      suggestions.push "Palabras al revés no son más difíciles de adivinar"
    if match.l33t
      suggestions.push "Sustituciones predecibles como '@' por 'a' o '1' por 'i' no mejoran mucho tu contraseña"

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
