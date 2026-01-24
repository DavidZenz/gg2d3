HTMLWidgets.widget({
  name: 'gg2d3',
  type: 'output',

  factory: function (el, width, height) {

    // ---------- helpers ----------
    function val(v) { return Array.isArray(v) ? (v.length ? v[0] : null) : v; }
    function num(v) { v = val(v); if (v == null || v === "") return null; const n = +v; return Number.isFinite(n) ? n : null; }
    function isHexColor(s) { return typeof s === "string" && /^#([0-9a-f]{3}|[0-9a-f]{6})$/i.test(s); }

    // Convert column-oriented object {col:[...], ...} to row array [{col:..}, ...]
    function asRows(dat) {
      if (Array.isArray(dat)) return dat;                 // already rows
      if (dat && typeof dat === "object") {
        const keys = Object.keys(dat);
        if (!keys.length) return [];
        const len = (dat[keys[0]] || []).length;
        const rows = new Array(len);
        for (let i = 0; i < len; i++) {
          const r = {};
          for (const k of keys) r[k] = dat[k] ? dat[k][i] : null;
          rows[i] = r;
        }
        return rows;
      }
      return [];
    }

    function makeScale(desc, range) {
      const rng = Array.isArray(range) ? range : [0, 1];
      if (!desc) return d3.scaleLinear().domain([0, 1]).range(rng);

      const type = typeof desc.type === "string" ? desc.type.toLowerCase() : desc.type;
      const transform = typeof desc.transform === "string"
        ? desc.transform.toLowerCase()
        : (typeof desc.trans === "string" ? desc.trans.toLowerCase() : undefined);
      const domainArr = Array.isArray(desc.domain) ? desc.domain : [];
      const numericValues = domainArr
        .map(d => (typeof d === "number" ? d : +d))
        .filter(v => Number.isFinite(v));
      const hasNumericDomain = domainArr.length && numericValues.length === domainArr.length;
      const numericDomain = numericValues.length ? numericValues : [0, 1];
      const dateDomain = (() => {
        const parsed = domainArr
          .map(d => (d instanceof Date ? d : new Date(d)))
          .filter(d => d instanceof Date && !Number.isNaN(+d));
        return parsed.length ? parsed : [new Date(0), new Date(1)];
      })();

      const buildScale = kind => {
        switch (kind) {
          case "continuous":
          case "linear":
          case "identity":
            return d3.scaleLinear().domain(numericDomain).range(rng);

          case "log":
          case "logarithmic":
          case "log10":
          case "log2": {
            const positive = numericDomain.filter(v => v > 0);
            const domain = positive.length ? positive : [1, 10];
            const scale = d3.scaleLog().domain(domain).range(rng);
            const base = desc.base || (kind === "log2" ? 2 : kind === "log10" ? 10 : null);
            if (base) scale.base(base);
            return scale;
          }

          case "sqrt":
          case "square-root":
            return d3.scaleSqrt().domain(numericDomain).range(rng);

          case "pow":
          case "power": {
            const exponent = [desc.exponent, desc.power, desc.exp]
              .map(v => (v == null ? null : +v))
              .find(v => Number.isFinite(v));
            const scale = d3.scalePow().exponent(exponent != null ? exponent : 1).domain(numericDomain).range(rng);
            return scale;
          }

          case "symlog":
          case "sym-log": {
            const scale = d3.scaleSymlog().domain(numericDomain).range(rng);
            if (desc.constant != null && Number.isFinite(+desc.constant)) scale.constant(+desc.constant);
            return scale;
          }

          case "time":
          case "date":
          case "datetime":
            return d3.scaleTime().domain(dateDomain).range(rng);

          case "utc":
          case "time-utc":
            return d3.scaleUtc().domain(dateDomain).range(rng);

          case "band":
          case "categorical":
          case "ordinal":
          case "discrete": {
            const band = d3.scaleBand().domain(domainArr).range(rng);
            if (desc.paddingInner != null || desc.paddingOuter != null) {
              if (desc.paddingInner != null && Number.isFinite(+desc.paddingInner)) band.paddingInner(+desc.paddingInner);
              if (desc.paddingOuter != null && Number.isFinite(+desc.paddingOuter)) band.paddingOuter(+desc.paddingOuter);
            } else if (desc.padding != null && Number.isFinite(+desc.padding)) {
              band.padding(+desc.padding);
            } else {
              band.padding(0.1);
            }
            if (desc.align != null && Number.isFinite(+desc.align)) band.align(+desc.align);
            return band;
          }

          case "point": {
            const point = d3.scalePoint().domain(domainArr).range(rng);
            if (desc.padding != null && Number.isFinite(+desc.padding)) point.padding(+desc.padding);
            if (desc.align != null && Number.isFinite(+desc.align)) point.align(+desc.align);
            return point;
          }

          case "quantize":
            if (Array.isArray(desc.range)) {
              return d3.scaleQuantize().domain(numericDomain).range(desc.range);
            }
            return null;

          case "quantile":
            if (Array.isArray(desc.range)) {
              return d3.scaleQuantile().domain(numericDomain).range(desc.range);
            }
            return null;

          case "threshold":
            if (Array.isArray(desc.range)) {
              return d3.scaleThreshold().domain(numericDomain).range(desc.range);
            }
            return null;

          default:
            return null;
        }
      };

      const fromType = buildScale(type);
      if (fromType) return fromType;

      if (transform) {
        const fromTransform = buildScale(transform);
        if (fromTransform) return fromTransform;
      }

      if (!domainArr.length) return d3.scaleLinear().domain(numericDomain).range(rng);

      if (hasNumericDomain) {
        return d3.scaleLinear().domain(numericDomain).range(rng);
      }

      return d3.scaleBand().domain(domainArr).range(rng).padding(0.1);
    }

    // ---------- draw ----------
    function draw(ir, elW, elH) {
      d3.select(el).selectAll("*").remove();

      const pad = ir.padding || { top: 20, right: 20, bottom: 40, left: 50 };
      const innerW = ir.width || elW || 640;
      const innerH = ir.height || elH || 400;
      const w = Math.max(10, innerW - pad.left - pad.right);
      const h = Math.max(10, innerH - pad.top - pad.bottom);

      const root = d3.select(el).append("svg").attr("width", innerW).attr("height", innerH);
      const g = root.append("g").attr("transform", `translate(${pad.left},${pad.top})`);

      const flip = !!(ir.coord && ir.coord.flip);
      let xScale = makeScale(ir.scales && ir.scales.x, flip ? [h, 0] : [0, w]);
      let yScale = makeScale(ir.scales && ir.scales.y, flip ? [0, w] : [h, 0]);

      // Axes - position x-axis at y=0 if 0 is in domain
      if (flip) {
        g.append("g").call(d3.axisLeft(xScale));
        g.append("g").attr("transform", `translate(0,${h})`).call(d3.axisBottom(yScale));
      } else {
        // Check if y-scale includes 0 and position x-axis accordingly
        let xAxisY = h;
        if (typeof yScale.bandwidth !== "function") {
          const yDomain = yScale.domain();
          const [yMin, yMax] = d3.extent(yDomain);
          if (yMin <= 0 && yMax >= 0) {
            xAxisY = yScale(0);
          }
        }
        g.append("g").attr("transform", `translate(0,${xAxisY})`).call(d3.axisBottom(xScale));
        g.append("g").call(d3.axisLeft(yScale));
      }

      // Title
      if (ir.title) {
        root.append("text")
          .attr("x", innerW / 2).attr("y", Math.max(14, pad.top * 0.6))
          .attr("text-anchor", "middle").style("font-weight", 600)
          .text(ir.title);
      }

      // Colors
      const cdesc = ir.scales && ir.scales.color;
      const colorScale = cdesc
        ? (cdesc.type === "continuous"
            ? d3.scaleSequential(d3.interpolateTurbo).domain(d3.extent(cdesc.domain || [0, 1]))
            : d3.scaleOrdinal(d3.schemeTableau10).domain(cdesc.domain || []))
        : () => null;

      let drawn = 0;

      (ir.layers || []).forEach(layer => {
        const dat = asRows(layer.data);             // <-- key fix
        const aes = layer.aes || {};
        const get = (d, k) => (k && d != null) ? d[k] : null;

        // Get stroke/border color
        const strokeColor = d => {
          if (aes.color) {
            const v = val(get(d, aes.color));
            if (isHexColor(v)) return v;           // ggplot already mapped to hex
            const mapped = colorScale(v);
            return mapped || (layer.params && layer.params.colour) || "currentColor";
          }
          return (layer.params && layer.params.colour) || "currentColor";
        };

        // Get fill color
        const fillColor = d => {
          if (aes.fill) {
            const v = val(get(d, aes.fill));
            if (isHexColor(v)) return v;
            const mapped = colorScale(v);
            return mapped || (layer.params && layer.params.fill) || "grey35";
          }
          return (layer.params && layer.params.fill) || "grey35";
        };
        const opa = d => {
          if (aes.alpha) {
            const v = val(get(d, aes.alpha));
            return (v == null ? 1 : +v);
          }
          return 1;
        };

        if (layer.geom === "point") {
          const isXBand = typeof xScale.bandwidth === "function";
          const isYBand = typeof yScale.bandwidth === "function";

          const pts = dat.filter(d => {
            const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
            const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
            return xVal != null && yVal != null;
          });
          const defaultSize = (layer.params && layer.params.size) || 1.5;

          const sel = g.append("g").selectAll("circle").data(pts);
          sel.enter().append("circle")
            .attr("cx", d => {
              const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
              return xScale(xVal);
            })
            .attr("cy", d => {
              const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
              return yScale(yVal);
            })
            .attr("r", d => {
              if (aes.size) {
                return Math.max(0.5, +(val(get(d, aes.size))) || defaultSize);
              }
              return defaultSize;
            })
            .attr("fill", d => fillColor(d))
            .attr("stroke", d => strokeColor(d))
            .attr("stroke-width", 0.5)
            .attr("opacity", d => opa(d));
          drawn += pts.length;

        } else if (layer.geom === "line" || layer.geom === "path") {
          const isXBand = typeof xScale.bandwidth === "function";
          const isYBand = typeof yScale.bandwidth === "function";

          const grouped = d3.group(dat, d => val(get(d, "group")) ?? 1);
          grouped.forEach(arr => {
            let pts = arr
              .map(d => {
                const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
                const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
                return { x: xVal, y: yVal, d };
              })
              .filter(p => p.x != null && p.y != null);

            // Only sort for geom_line (and only if x is numeric)
            if (layer.geom === "line" && !isXBand) {
              pts = pts.sort((a, b) => d3.ascending(a.x, b.x));
            }

            if (pts.length >= 2) {
              const line = d3.line().x(p => xScale(p.x)).y(p => yScale(p.y));
              g.append("path")
                .attr("d", line(pts))
                .attr("fill", "none")
                .attr("stroke", strokeColor(pts[0].d))
                .attr("stroke-width", 1.5)
                .attr("opacity", opa(pts[0].d));
              drawn += 1;
            }
          });

        } else if (layer.geom === "bar" || layer.geom === "col") {
          const isBand = typeof xScale.bandwidth === "function";
          const bw = isBand ? xScale.bandwidth() : Math.max(4, w / Math.max(1, dat.length));

          // For categorical x, use val(); for continuous, use num()
          const bars = dat.filter(d => {
            const xVal = isBand ? val(get(d, aes.x)) : num(get(d, aes.x));
            const yVal = num(get(d, aes.y));
            return xVal != null && yVal != null;
          });

          // Check if data has ymin/ymax (for stacked bars)
          const hasStack = bars.length > 0 && get(bars[0], "ymin") != null && get(bars[0], "ymax") != null;

          // Calculate baseline: use 0 if in domain, else use domain min
          let baseline;
          if (!hasStack) {
            const yDomain = yScale.domain();
            if (typeof yScale.bandwidth === "function") {
              baseline = h;
            } else {
              const [yMin, yMax] = d3.extent(yDomain);
              if (yMin <= 0 && yMax >= 0) {
                baseline = yScale(0);
              } else {
                baseline = yScale(yMin);
              }
            }
          }

          const sel = g.append("g").selectAll("rect").data(bars);
          sel.enter().append("rect")
            .attr("x", d => (isBand ? xScale(val(get(d, aes.x))) : xScale(num(get(d, aes.x))) - bw / 2))
            .attr("y", d => {
              if (hasStack) {
                // Use ymax for top of bar segment
                return yScale(num(get(d, "ymax")));
              } else {
                const yPos = yScale(num(get(d, aes.y)));
                return Math.min(yPos, baseline);
              }
            })
            .attr("width", bw)
            .attr("height", d => {
              if (hasStack) {
                // Height from ymin to ymax
                const yMinPos = yScale(num(get(d, "ymin")));
                const yMaxPos = yScale(num(get(d, "ymax")));
                return Math.abs(yMaxPos - yMinPos);
              } else {
                return Math.abs(yScale(num(get(d, aes.y))) - baseline);
              }
            })
            .attr("fill", d => fillColor(d))
            .attr("opacity", d => opa(d));
          drawn += bars.length;

        } else if (layer.geom === "rect") {
          const rects = dat.filter(d =>
            get(d, aes.xmin) != null && get(d, aes.xmax) != null &&
            get(d, aes.ymin) != null && get(d, aes.ymax) != null
          );

          const isXBand = typeof xScale.bandwidth === "function";
          const isYBand = typeof yScale.bandwidth === "function";

          const sel = g.append("g").selectAll("rect").data(rects);
          sel.enter().append("rect")
            .attr("x", d => {
              const xmin = isXBand ? val(get(d, aes.xmin)) : num(get(d, aes.xmin));
              return xScale(xmin);
            })
            .attr("y", d => {
              const ymax = isYBand ? val(get(d, aes.ymax)) : num(get(d, aes.ymax));
              return yScale(ymax);
            })
            .attr("width", d => {
              if (isXBand) return xScale.bandwidth();
              const x1 = xScale(num(get(d, aes.xmin)));
              const x2 = xScale(num(get(d, aes.xmax)));
              return Math.abs(x2 - x1);
            })
            .attr("height", d => {
              if (isYBand) return yScale.bandwidth();
              const y1 = yScale(num(get(d, aes.ymin)));
              const y2 = yScale(num(get(d, aes.ymax)));
              return Math.abs(y2 - y1);
            })
            .attr("fill", d => fillColor(d))
            .attr("opacity", d => opa(d));
          drawn += rects.length;

        } else if (layer.geom === "text") {
          const isXBand = typeof xScale.bandwidth === "function";
          const isYBand = typeof yScale.bandwidth === "function";

          const txt = dat.filter(d => {
            const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
            const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
            return xVal != null && yVal != null;
          });
          const sel = g.append("g").selectAll("text").data(txt);
          sel.enter().append("text")
            .attr("x", d => {
              const xVal = isXBand ? val(get(d, aes.x)) : num(get(d, aes.x));
              return xScale(xVal);
            })
            .attr("y", d => {
              const yVal = isYBand ? val(get(d, aes.y)) : num(get(d, aes.y));
              return yScale(yVal);
            })
            .attr("dominant-baseline", "middle")
            .attr("text-anchor", "middle")
            .text(d => val(get(d, aes.label)))
            .attr("fill", d => strokeColor(d))
            .attr("opacity", d => opa(d))
            .style("font-size", "10px");
          drawn += txt.length;
        }
      });

      if (!drawn) {
        console.warn("gg2d3: no marks drawn — check aes names and data types", ir);
        root.append("circle").attr("cx", innerW/2).attr("cy", innerH/2).attr("r", 6).attr("fill", "tomato");
      }
    }

    // ---------- widget API ----------
    return {
      renderValue: function (x) {
        let ir = (x && x.ir !== undefined) ? x.ir : x;
        if (typeof ir === "string") {
          try { ir = JSON.parse(ir); } catch (e) { console.error("gg2d3: JSON parse failed:", e, ir); return; }
        }
        if (!ir || !ir.scales) {
          console.warn("gg2d3: invalid IR payload", ir);
          d3.select(el).selectAll("*").remove();
          d3.select(el).append("svg").attr("width", width).attr("height", height)
            .append("rect").attr("x", 20).attr("y", 20).attr("width", 200).attr("height", 100).attr("fill", "tomato");
          return;
        }
        draw(ir, width, height);
      },
      resize: function () { /* store & redraw if needed */ }
    };
  }
});
