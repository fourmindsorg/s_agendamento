(function ($) {
    'use strict';

    $(document).ready(function () {
        // Função para calcular data_fim baseada no plano selecionado
        function calcularDataFim() {
            var planoSelect = $('#id_plano');
            var dataFimInput = $('#id_data_fim');

            if (planoSelect.length && dataFimInput.length) {
                var planoId = planoSelect.val();

                if (planoId) {
                    // Fazer requisição AJAX para obter duração do plano
                    $.ajax({
                        url: '/authentication/ajax/plano/' + planoId + '/duracao/',
                        method: 'GET',
                        success: function (data) {
                            if (data.success && !dataFimInput.val()) {
                                var duracaoDias = data.duracao_dias;

                                // Calcular data_fim
                                var hoje = new Date();
                                var dataFim = new Date(hoje.getTime() + (parseInt(duracaoDias) * 24 * 60 * 60 * 1000));

                                // Formatar para o formato esperado pelo Django (YYYY-MM-DD HH:MM:SS)
                                var ano = dataFim.getFullYear();
                                var mes = String(dataFim.getMonth() + 1).padStart(2, '0');
                                var dia = String(dataFim.getDate()).padStart(2, '0');
                                var hora = String(dataFim.getHours()).padStart(2, '0');
                                var minuto = String(dataFim.getMinutes()).padStart(2, '0');
                                var segundo = String(dataFim.getSeconds()).padStart(2, '0');

                                var dataFormatada = ano + '-' + mes + '-' + dia + ' ' + hora + ':' + minuto + ':' + segundo;
                                dataFimInput.val(dataFormatada);
                            }
                        },
                        error: function () {
                            console.log('Erro ao obter dados do plano');
                        }
                    });
                }
            }
        }

        // Executar quando o plano for alterado
        $('#id_plano').on('change', calcularDataFim);

        // Executar na carga inicial se já houver um plano selecionado
        if ($('#id_plano').val()) {
            calcularDataFim();
        }
    });
})(django.jQuery);
