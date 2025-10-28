
document.addEventListener('DOMContentLoaded', function() {
    // Auto-submit do formulário de busca ao digitar (com delay)
    let searchTimeout;
    const searchInput = document.getElementById('search');
    
    if (searchInput) {
        searchInput.addEventListener('input', function() {
            clearTimeout(searchTimeout);
            searchTimeout = setTimeout(function() {
                // Auto-submit após 1.5 segundos de inatividade
                // document.querySelector('form').submit();
            }, 1500);
        });
    }
    
    // Destacar linha ao passar o mouse
    const agendamentoRows = document.querySelectorAll('.agendamento-row');
    agendamentoRows.forEach(row => {
        row.addEventListener('mouseenter', function() {
            this.style.backgroundColor = 'var(--light-color)';
        });
        
        row.addEventListener('mouseleave', function() {
            const status = this.getAttribute('data-status');
            if (status === 'concluido') {
                this.style.backgroundColor = 'rgba(40, 167, 69, 0.05)';
            } else if (status === 'cancelado') {
                this.style.backgroundColor = 'rgba(220, 53, 69, 0.05)';
            } else {
                this.style.backgroundColor = '';
            }
        });
    });
    
    // Confirmação de exclusão
    const deleteButtons = document.querySelectorAll('[data-bs-target^="#deleteModal"]');
    deleteButtons.forEach(button => {
        button.addEventListener('click', function() {
            const row = this.closest('tr, .list-group-item');
            const clienteName = row.querySelector('strong').textContent;
            console.log('Preparando exclusão do agendamento de:', clienteName);
        });
    });
    
    // Atualizar data de hoje nos filtros rápidos
    const hoje = new Date().toISOString().split('T')[0];
    const filtroHoje = document.querySelector('a[href*="data_inicio"]');
    if (filtroHoje) {
        filtroHoje.href = filtroHoje.href.replace(/data_inicio=[^&]*/, `data_inicio=${hoje}`);
        filtroHoje.href = filtroHoje.href.replace(/data_fim=[^&]*/, `data_fim=${hoje}`);
    }
});
