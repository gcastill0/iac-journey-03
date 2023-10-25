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

    const target_groups = ["region", "vpc", "az-all", "security-group", "ec2", "icon-alb", "users"]

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

    console.table(target_groups)

    document.addEventListener('keydown', (e) => {

        if (counter > target_groups.length - 1) {
            console.log("from", counter, "to", target_groups.length - 1)
            counter = target_groups.length - 1
        } else if (counter <= 0) {
            console.log("from", counter, "to", 0)
            counter = 0
        }

        console.log("Current:", counter, target_groups[counter])

        switch (e.key) {
            case "ArrowRight":
                // setActive(counter)
                document.getElementById(target_groups[counter]).style.display = "block"
                counter++
                break
            case "ArrowLeft":
                // setInactive(counter)
                document.getElementById(target_groups[counter]).style.display = "none"
                counter--
                break
        }

        console.log("Next:", counter, target_groups[counter], "\n")

    })

}