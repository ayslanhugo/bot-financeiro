import "@hotwired/turbo-rails"
import "controllers"

// Importa da CDN definida no importmap
import { Chart, registerables } from "chart.js"

// Registra os componentes
Chart.register(...registerables)

// Torna global
window.Chart = Chart

// Carrega o Chartkick
import "chartkick"