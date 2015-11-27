function ErrorRegion(x, y, err, colour, alpha)
% ErrorRegion Draw error region as a patch with colour and opacity

    patch([x; flipud(x)],[y-err; flipud(y+err)],colour,'FaceAlpha',alpha,'LineStyle','none')
