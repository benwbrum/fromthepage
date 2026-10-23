import { Chart, registerables } from "chart.js";
Chart.register(...registerables);

/**
 * useStackedBarRenderer - Handles Stacked Bar chart data rendering
 *
 * Responsibilities:
 * - Handles initialization and rendering of stacked bar charts
 *
 * Payload Shape:
 * - labels: String[]
 * - datasets: [{
 *     label: String,
 *     data: Number[]
 *     backgroundColor: String
 *   }]
 * - colors: String[]
 * - legendPosition: String
 * - options: Object
 *
 * @param {Object} controller - Stimulus controller instance
 */
const useStackedBarRenderer = (controller) => {
  if (!controller) {
    console.error('useStackedBarRenderer requires a Stimulus controller instance.');
  };

  Object.defineProperty(controller, 'chartData', {
    get() { return controller._chartData || {} },
    set(payload) {
      const colors = payload.colors || [];

      const datasets = (payload.datasets || []).map((ds, i) => ({
        label: ds.label || `Dataset ${i + 1}`,
        data: ds.data || [],
        backgroundColor: ds.backgroundColor || colors[i] || '#888888',
        borderColor: ds.borderColor || '#000000',
        borderWidth: ds.borderWidth ?? 0.3,
        borderRadius: ds.borderRadius ?? 0,
        borderSkipped: false
      }));

      controller._chartData = {
        labels: payload.labels || [],
        datasets
      };
    }
  });

  Object.defineProperty(controller, 'chartOptions', {
    get() { return controller._chartOptions || {} },
    set(payload) {
      const legendPosition = payload.legendPosition || 'bottom';
      const customOptions = payload.options || {};

      controller._chartOptions = {
        indexAxis: 'y',
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: { stacked: true, display: false },
          y: { stacked: true, display: false }
        },
        plugins: {
          legend: { position: legendPosition },
          tooltip: { enabled: payload.tooltipEnabled }
        },
        ...customOptions
      };
    }
  });

  Object.defineProperty(controller, 'chartPlugins', {
    get() { return controller._chartPlugins || [] },
    set(payload) {
      controller._chartPlugins = Array.isArray(payload) ? payload : [];
    }
  });

  const render = () => {
    const ctx = controller.canvasTarget.getContext('2d');
    controller.chartData = controller.payloadValue.data || {};
    controller.chartOptions = controller.payloadValue;
    controller.chartPlugins = controller.payloadValue.plugins || [];

    controller.graph = new Chart(ctx, {
      type: 'bar',
      data: controller.chartData,
      options: controller.chartOptions,
      plugins: controller.chartPlugins
    });
  }

  return { render };
};

export default useStackedBarRenderer;
