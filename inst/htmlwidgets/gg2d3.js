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
      if (!desc || !desc.type) return d3.scaleLinear().domain([0, 1]).range(range);
      if (desc.type === "continuous") return d3.scaleLinear().domain(desc.domain || [0, 1]).range(range);
      if (desc.type === "time") {
        const dom = (desc.domain || []).map(d => (d instanceof Date ? d : new Date(d)));
        return d3.scaleTime().domain(dom).range(range);
      }
      return d3.scaleBand().domain(desc.domain || []).range(range).padding(0.1);
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
      g.append("g").attr("transform", `translate(0,${h})`).call(d3.axisBottom(xScale));
      g.append("g").call(d3.axisLeft(yScale));

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
