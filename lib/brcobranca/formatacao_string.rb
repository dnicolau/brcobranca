# frozen_string_literal: true

module Brcobranca
  # Métodos auxiliares de formatação de strings
  module FormatacaoString
    # Formata o tamanho da string
    # para o tamanho passado
    # se a string for menor, adiciona espacos a direita
    # se a string for maior, trunca para o num. de caracteres
    #
    def format_size(size)
      data = remove_accents.strip.gsub(/\s+/, ' ').gsub(/[^A-Za-z0-9[[:space:]]]/, '')
      if data.size > size
        data.slice(0, size)
      else
        data.ljust(size, ' ')
      end
    end

    def remove_accents
      tr(
        'ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž',
        'AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz'
      )
    end
  end
end

[String].each do |klass|
  klass.class_eval { include Brcobranca::FormatacaoString }
end
