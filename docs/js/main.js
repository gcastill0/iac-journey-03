window.onload = function () {
    const parser = new DOMParser();

    async function fetchSVG(svg_name) {
        const response = await fetch(svg_name);
        const svgText = await response.text();
        const svgDoc = parser.parseFromString(svgText, 'text/xml');
        return svgDoc;
    }

    const topology = document.getElementById("topology")

    fetchSVG("img/topology.svg").then(imageSVG => {
        topology.appendChild(imageSVG.documentElement);
    });
}