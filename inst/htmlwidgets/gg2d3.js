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

      // Axes
      if (flip) {
        g.append("g").call(d3.axisLeft(xScale));
        g.append("g").attr("transform", `translate(0,${h})`).call(d3.axisBottom(yScale));
      } else {
        g.append("g").attr("transform", `translate(0,${h})`).call(d3.axisBottom(xScale));
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

        const col = d => {
          if (aes.color) {
            const v = val(get(d, aes.color));
            if (isHexColor(v)) return v;           // ggplot already mapped to hex
            const mapped = colorScale(v);
            return mapped || "currentColor";
          }
          return "currentColor";
        };
        const opa = d => {
          if (aes.alpha) {
            const v = val(get(d, aes.alpha));
            return (v == null ? 1 : +v);
          }
          return 1;
        };

        if (layer.geom === "point") {
          const pts = dat.filter(d => num(get(d, aes.x)) != null && num(get(d, aes.y)) != null);
          const sel = g.append("g").selectAll("circle").data(pts);
          sel.enter().append("circle")
            .attr("cx", d => xScale(num(get(d, aes.x))))
            .attr("cy", d => yScale(num(get(d, aes.y))))
            .attr("r", d => Math.max(1.8, +(val(get(d, aes.size))) || 2))
            .attr("fill", d => col(d))
            .attr("opacity", d => opa(d));
          drawn += pts.length;

        } else if (layer.geom === "line" || layer.geom === "path") {
          const grouped = d3.group(dat, d => val(get(d, "group")) ?? 1);
          grouped.forEach(arr => {
            const pts = arr
              .map(d => ({ x: num(get(d, aes.x)), y: num(get(d, aes.y)), d }))
              .filter(p => p.x != null && p.y != null)
              .sort((a, b) => d3.ascending(a.x, b.x));
            if (pts.length >= 2) {
              const line = d3.line().x(p => xScale(p.x)).y(p => yScale(p.y));
              g.append("path")
                .attr("d", line(pts))
                .attr("fill", "none")
                .attr("stroke", col(pts[0].d))
                .attr("stroke-width", 1.5)
                .attr("opacity", opa(pts[0].d));
              drawn += 1;
            }
          });

        } else if (layer.geom === "bar" || layer.geom === "col") {
          const isBand = typeof xScale.bandwidth === "function";
          const bw = isBand ? xScale.bandwidth() : Math.max(4, w / Math.max(1, dat.length));
          const bars = dat.filter(d => num(get(d, aes.x)) != null && num(get(d, aes.y)) != null);
          const sel = g.append("g").selectAll("rect").data(bars);
          sel.enter().append("rect")
            .attr("x", d => (isBand ? xScale(val(get(d, aes.x))) : xScale(num(get(d, aes.x))) - bw / 2))
            .attr("y", d => yScale(num(get(d, aes.y))))
            .attr("width", bw)
            .attr("height", d => Math.max(0, (yScale(0) ?? h) - yScale(num(get(d, aes.y)))))
            .attr("fill", d => col(d))
            .attr("opacity", d => opa(d));
          drawn += bars.length;

        } else if (layer.geom === "rect") {
          const rects = dat.filter(d =>
            num(get(d, aes.xmin)) != null && num(get(d, aes.xmax)) != null &&
            num(get(d, aes.ymin)) != null && num(get(d, aes.ymax)) != null
          );
          const sel = g.append("g").selectAll("rect").data(rects);
          sel.enter().append("rect")
            .attr("x", d => xScale(num(get(d, aes.xmin))))
            .attr("y", d => yScale(num(get(d, aes.ymax))))
            .attr("width", d => Math.max(0, xScale(num(get(d, aes.xmax))) - xScale(num(get(d, aes.xmin)))))
            .attr("height", d => Math.max(0, yScale(num(get(d, aes.ymin))) - yScale(num(get(d, aes.ymax)))))
            .attr("fill", d => col(d))
            .attr("opacity", d => opa(d));
          drawn += rects.length;

        } else if (layer.geom === "text") {
          const txt = dat.filter(d => num(get(d, aes.x)) != null && num(get(d, aes.y)) != null);
          const sel = g.append("g").selectAll("text").data(txt);
          sel.enter().append("text")
            .attr("x", d => xScale(num(get(d, aes.x))))
            .attr("y", d => yScale(num(get(d, aes.y))))
            .attr("dominant-baseline", "middle")
            .attr("text-anchor", "middle")
            .text(d => val(get(d, aes.label)))
            .attr("fill", d => col(d))
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
