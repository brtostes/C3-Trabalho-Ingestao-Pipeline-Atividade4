{% macro normalizar_nome(expressao, regex_remover=none) %}

    trim(
        regexp_replace(
            regexp_replace(
                translate(
                    upper(
                        {% if regex_remover %}
                            regexp_replace(
                                trim({{ expressao }}),
                                '{{ regex_remover }}',
                                '',
                                'i'
                            )
                        {% else %}
                            trim({{ expressao }})
                        {% endif %}
                    ),
                    'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
                    'AAAAAEEEEIIIIOOOOOUUUUC'
                ),
                '[^A-Z0-9]+',
                ' ',
                'g'
            ),
            '[[:space:]]+',
            ' ',
            'g'
        )
    )

{% endmacro %}