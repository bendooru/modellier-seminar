function [t_auf, visible] = sonnenaufgang(p, tag)
    tag_dauer = 1440;
    t_auf = tag*tag_dauer;
    visible = true;
    
    while (sun_visible(t_auf))
        t_auf = t_auf - 1;
        if t_auf <= (tag-1)*tag_dauer
            t_auf = tag*tag_dauer;
            break;
        end
    end
    
    while (~sun_visible(t_auf))
        t_auf = t_auf + 1;
        if t_auf >= (tag+1)*tag_dauer
            t_auf = tag*tag_dauer;
            visible = false;
            break;
        end
    end
    
    function vis = sun_visible(t)
        sonPos = sonnen_pos(t) - p;
        sun_ele = vector_angle(p, sonPos);
        vis = 0 <= sun_ele && sun_ele <= pi/2;
    end
end