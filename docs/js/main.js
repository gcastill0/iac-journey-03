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

    let counter = 0;

    const target_groups = ["aws", "region", "vpc", "az-all", "security-group", "ec2", "icon-alb", "users"]

    function waitForSVGElement(selector) {
        return new Promise(resolve => {
            if (document.getElementById(selector)) {
                return resolve(document.getElementById(selector));
            }

            const observer = new MutationObserver(mutations => {
                if (document.getElementById(selector)) {
                    observer.disconnect();
                    resolve(document.getElementById(selector));
                }
            });

            observer.observe(document.body, {
                childList: true,
                subtree: true
            });
        });
    }

    waitForSVGElement(target_groups[counter]).then((element) => {
        document.getElementById("aws").style.display = "block"
    })

    document.addEventListener('keydown', (e) => {

        switch (e.key) {
            case "ArrowRight":
                counter = (counter < target_groups.length - 1) ? counter + 1 : target_groups.length - 1
                document.getElementById(target_groups[counter]).style.display = "block"
                break

            case "ArrowLeft":
                if (counter == 0) break
                document.getElementById(target_groups[counter]).style.display = "none"
                counter = (counter > 1) ? counter - 1 : 0
                break
        }

    })

}